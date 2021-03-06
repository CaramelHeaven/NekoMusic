//
//  TrackListKnot.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 22/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit
import SwiftUI

final class TrackListKnot {
    private let remote: GoogleDrive
    private let preferences: UserPreferences
    private let database: Database

    private lazy var databaseSync: DatabaseSynchronization = {
        diContainer.resolve(type: DatabaseSynchronization.self)
    }()

    init(_ remote: GoogleDrive, _ local: Database, _ preferences: UserPreferences) {
        self.remote = remote
        self.preferences = preferences
        self.database = local
    }

    func userableTracks(_ isSyncNeeded: Bool) -> Promise<[Track]> {
        firstly {
            self.checkNewTracksIfNeeded(isSyncNeeded)
        }.then {
            self.tracks()
        }
    }

    func locallyPush() -> Promise<Void> {
        databaseSync.sync(.toRemote)
    }

    private func checkNewTracksIfNeeded(_ isCheckNeeded: Bool) -> Promise<Void> {
        guard isCheckNeeded || preferences.isAppFirstLaunched else {
            return Promise.value
        }

        return firstly {
            self.database.extractableItems(decode: Track.self)
        }.then {
            self.download($0)
        }
    }
}

fileprivate extension TrackListKnot {
    func tracks() -> Promise<[Track]> {
        firstly {
            database.extractableItems(decode: Track.self)
        }.then { arr -> Promise<[Track]> in
            let result = arr.compactMap { t -> Track? in
                guard let url = self.database.disk.gettableFile(name: t.name) else {
                    return nil
                }
                t.localUrl = url

                return t
            }

            return Promise.value(result)
        }
    }

    func download(_ localTracks: [Track] = []) -> Promise<Void> {
        firstly {
            self.retrievableFolderId()
        }.then {
            self.remote.files(by: .filesByFolder($0))
        }.then { remote -> Promise<Void> in
            let notDownloadedTracks = remote.files.filter { f in !localTracks.contains(where: { f.name == $0.name }) }
            guard !notDownloadedTracks.isEmpty else {
                return Promise.value
            }

            return firstly {
                self.remote.downloadableTracks(files: notDownloadedTracks)
            }.then {
                self.database.save(items: $0)
            }.then {
                self.unuseableTracks(localTracks, remote.files)
            }.then {
                self.database.clearUnusedIfNeeded($0)
            }.then { _ in
                self.databaseSync.sync(.toRemote)
            }
        }
    }

    func unuseableTracks(_ localTracks: [Track], _ remoteFiles: [GoogleFile]) -> Promise<[Track]> {
        return Promise.value(localTracks.filter { t in !remoteFiles.contains(where: { t.name == $0.name }) })
    }

    func retrievableFolderId() -> Promise<String> {
        Promise { resolve in
            guard let folderId = preferences.serverFolderId else {
                throw NSError(domain: "Not found folder id in local storage", code: 0, userInfo: nil)
            }

            resolve.fulfill(folderId)
        }
    }
}
