//
//  Database.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 16/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit
import RealmSwift

final class Database {
    let disk: DiskStorage

    private let preferences: UserPreferences
    private var realm: Realm?

    init(_ fileStorage: DiskStorage, _ preferences: UserPreferences) {
        self.disk = fileStorage
        self.preferences = preferences

        let config = Realm.Configuration(fileURL: preferences.databasePath)
        self.realm = try? Realm(configuration: config)
    }

    func recreate(fileUrl: URL? = nil) -> Promise<Void> {
        Promise { resolve in
            do {
                let config = Realm.Configuration(fileURL: fileUrl)
                realm = try Realm(configuration: config)

                resolve.fulfill_()
            } catch {
                throw error
            }
        }
    }

    /// Remove the realm db file, this method needed if we want to use backup data for user in the future
    func remove() -> Promise<Void> {
        Promise<[Promise<Void>]> { resolve in
            guard let diskUrl = realm?.configuration.fileURL else {
                return resolve.reject(NSError(domain: "remove realm error", code: 0, userInfo: nil))
            }

            let result = [diskUrl, diskUrl.appendingPathExtension("lock"),
                          diskUrl.appendingPathExtension("note"),
                          diskUrl.appendingPathExtension("management")].map { self.disk.remove(fileUrl: $0) }

            resolve.fulfill(result)
        }.then {
            when(resolved: $0)
        }.then { _ in
            Promise.value
        }
    }

    func extractableItems<T: Object>(decode: T.Type) -> Promise<[T]> {
        Promise { resolve in
            guard let realm = realm else {
                throw NSError(domain: "Realm is nil", code: 0, userInfo: nil)
            }
            resolve.fulfill(Array(realm.objects(T.self)))
        }
    }

    func save<T: Object>(items: [T]) -> Promise<Void> {
        Promise { resolve in
            do {
                realm?.beginWrite()
                realm?.add(items, update: .modified)

                try realm?.commitWrite()

                resolve.fulfill_()
            } catch {
                throw error
            }
        }
    }
}

// MARK: - External API

extension Database {
    func clearUnusedIfNeeded(_ unusedTracks: [Track]) -> Promise<Void> {
        Promise { resolve in
            guard !unusedTracks.isEmpty else {
                return resolve.fulfill_()
            }
            do {
                realm?.beginWrite()
                realm?.delete(unusedTracks)
                try realm?.commitWrite()

                resolve.fulfill_()
            } catch {
                throw error
            }
        }
    }

    func tracks() -> Promise<[Track]> {
        firstly {
            extractableItems(decode: Track.self)
        }.then { arr -> Promise<[Track]> in
            let result = arr.compactMap { t -> Track? in
                guard let url = self.disk.gettableFile(name: t.name) else {
                    return nil
                }
                t.localUrl = url

                return t
            }

            return Promise.value(result)
        }
    }
}

// MARK: - For Tracks

// rewrite
extension Database {
    func savePlaylist(_ tracks: [Track], _ playlistName: String) -> Promise<Void> {
        Promise { resolve in
            do {
                realm?.beginWrite()

                tracks.forEach { track in
                    if let playlist = realm?.object(ofType: Playlist.self, forPrimaryKey: playlistName),
                        playlist.name == playlistName {
                        // If playlist not exist at track list - add, otherwise we dont need to add a duplicate
                        if !track.playlists.contains(playlist) {
                            track.playlists.append(playlist)
                        }
                    } else {
                        track.playlists.append(Playlist(name: playlistName))
                    }
                }

                try realm?.commitWrite()

                resolve.fulfill_()
            } catch {
                resolve.reject(error)
            }
        }
    }
}
