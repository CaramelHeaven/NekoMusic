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

    init(_ remote: GoogleDrive, _ local: Database, _ preferences: UserPreferences) {
        self.remote = remote
        self.preferences = preferences
        self.database = local
    }

    func userableTracks(_ isSyncNeeded: Bool) -> Promise<[Track]> {
        firstly {
            self.syncFromRemoteIfNeeded(isSyncNeeded)
        }.then { _ -> Promise<[Track]> in
            self.database.tracks()
        }
    }

    func addPlaylist(_ tracks: [Track], _ playlistName: String) -> Promise<Void> {
        firstly {
            self.database.savePlaylist(tracks, playlistName)
        }
    }

    private func syncFromRemoteIfNeeded(_ isSyncNeeded: Bool) -> Promise<Void> {
        guard isSyncNeeded else {
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
    enum SyncDirection {
        case toRemote
        case fromRemote
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
            }.then {
                self.syncabableDatabase(direction: .toRemote)
            }.then { _ in
                Promise.value
            }
        }
    }

    private func unuseableTracks(_ localTracks: [Track], _ remoteFiles: [GoogleFile]) -> Promise<[Track]> {
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

    // add direction in the future
    func syncabableDatabase(direction: SyncDirection) -> Promise<GoogleFile> {
        firstly {
            when(fulfilled: database.disk.gettableFile(by: "default.realm"), remote.remoteFile(fileName: "default.realm"))
        }.then { (localUrl, response) -> Promise<GoogleFile> in
            guard let localUrl = localUrl else {
                throw NSError(domain: "Realm db is not existed", code: 0, userInfo: nil)
            }

            guard !response.files.isEmpty, let file = response.files.first else {
                return self.remote.creationableFile(fileUrl: localUrl)
            }

            return self.remote.uploadableFile(by: file.id, fileUrl: localUrl)
        }
    }
}
