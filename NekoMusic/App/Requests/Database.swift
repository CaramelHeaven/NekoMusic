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
    let fileStorage: DiskStorage

    init(_ fileStorage: DiskStorage) {
        self.fileStorage = fileStorage
    }

    func extractableItems<T: Object>(decode: T.Type) -> Promise<[T]> {
        Promise { resolve in
            do {
                let realm = try Realm()

                resolve.fulfill(Array(realm.objects(T.self)))
            } catch {
                resolve.reject(error)
            }
        }
    }

    private func save<T: Object>(items: [T]) -> Promise<Void> {
        Promise { resolve in
            do {
                let realm = try Realm()

                realm.beginWrite()
                realm.add(items, update: .modified)

                try realm.commitWrite()

                resolve.fulfill_()
            } catch {
                resolve.reject(error)
            }
        }
    }
}

// MARK: - For Tracks

extension Database {
    func savePlaylist(_ tracks: [Track], _ playlistName: String) -> Promise<Void> {
        Promise { resolve in
            do {
                let realm = try Realm()
                realm.beginWrite()

                tracks.forEach { track in
                    if let playlist = realm.object(ofType: Playlist.self, forPrimaryKey: playlistName),
                        playlist.name == playlistName {
                        // If playlist not exist at track list - add, otherwise we dont need to add a duplicate
                        if !track.playlists.contains(playlist) {
                            track.playlists.append(playlist)
                        }
                    } else {
                        track.playlists.append(Playlist(name: playlistName))
                    }
                }

                try realm.commitWrite()

                resolve.fulfill_()
            } catch {
                resolve.reject(error)
            }
        }
    }

    func savingTracks(tracks: [Track]) -> Promise<[Track]> {
        firstly {
            self.removeUnusedTracks(newestTracks: tracks)
        }.then { _ in
            self.save(items: tracks)
        }.then { _ in
            Promise { $0.fulfill(tracks) }
        }
    }
}

fileprivate extension Database {
    func removeUnusedTracks(newestTracks: [Track]) -> Promise<Void> {
        Promise { resolve in
            do {
                let realm = try Realm()
                let oldTracks = Array(realm.objects(Track.self))

                // Set doesnt work properly here, curiously enough. Because "Simular" tracks has different instances and we need compare them by id
                let unusedTracks = oldTracks.compactMap { track -> Track? in
                    guard !newestTracks.contains(where: { $0.id == track.id }) else {
                        return nil
                    }
                    return track
                }

                if unusedTracks.isEmpty {
                    resolve.fulfill_()
                }

                self.removeTracksFromLocal(tracks: Array(unusedTracks)).done { _ in
                    realm.beginWrite()
                    realm.delete(unusedTracks)
                    try realm.commitWrite()

                    resolve.fulfill_()
                }.catch { resolve.reject($0) }
            } catch {
                resolve.reject(error)
            }
        }
    }

    func removeTracksFromLocal(tracks: [Track]) -> Promise<Void> {
        Promise { resolve in
            let group = DispatchGroup()

            tracks.forEach { track in
                group.enter()
                self.fileStorage.remove(fileName: track.name).done { _ in
                    group.leave()
                }.catch { resolve.reject($0) }
            }
            group.notify(queue: .global()) {
                resolve.fulfill_()
            }
        }
    }
}
