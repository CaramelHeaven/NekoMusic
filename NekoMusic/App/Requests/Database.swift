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

        let realmUrl = disk.gettableFile(name: "default.realm")
        let config = realmUrl != nil ? Realm.Configuration(fileURL: realmUrl) : Realm.Configuration()

        self.realm = try? Realm(configuration: config)
    }

    func recreate(fileUrl: URL) -> Promise<Void> {
        firstly {
            self.clear()
        }.then { _ in
            Promise { resolve in
                do {
                    let config = Realm.Configuration(fileURL: fileUrl)
                    self.realm = try Realm(configuration: config)

                    resolve.fulfill_()
                } catch {
                    throw error
                }
            }
        }
    }

    func extractableItems<T: Object>(decode _: T.Type) -> Promise<[T]> {
        Promise { resolve in
            guard let realm = realm else {
                throw NSError(domain: "Realm is nil", code: 0, userInfo: nil)
            }

            resolve.fulfill(realm.objects(T.self).toArray())
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

    func remove<T: Object>(items: [T]) -> Promise<Void> {
        Promise { resolve in
            realm?.beginWrite()
            realm?.delete(items)
            try realm?.commitWrite()

            resolve.fulfill_()
        }
    }

    func clearUnusedIfNeeded<T: Object>(_ unusedTracks: [T]) -> Promise<Void> {
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

    private func clear() -> Promise<Void> {
        Promise<[Promise<Void>]> { resolve in
            guard let diskUrl = realm?.configuration.fileURL else {
                return resolve.reject(NSError(domain: "remove realm error", code: 0, userInfo: nil))
            }
            self.realm = nil

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
}

// MARK: - Playlist DAO

extension Database {
    func createPlaylist(data: DataPlaylist) -> Promise<Void> {
        Promise { resolve in
            do {
                realm?.beginWrite()

                data.tracks.forEach { track in
                    guard let playlist = realm?.object(ofType: Playlist.self, forPrimaryKey: data.name) else {
                        track.playlists.append(Playlist(name: data.name))
                        return
                    }
                    guard !track.playlists.contains(playlist) else { return }

                    track.playlists.append(playlist)
                }

                try realm?.commitWrite()

                resolve.fulfill_()
            } catch {
                throw error
            }
        }
    }
}

fileprivate extension Results {
    /// Array(realm.objects(T)) doesnt work
    func toArray() -> [Element] {
        return compactMap { $0 }
    }
}
