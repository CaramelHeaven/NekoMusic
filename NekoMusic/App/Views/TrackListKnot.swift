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
    private let googleDrive: GoogleDrive
    private let preferences: UserPreferences
    private let database: Database

    init(_ googleDrive: GoogleDrive, _ preferences: UserPreferences, _ local: Database) {
        self.googleDrive = googleDrive
        self.preferences = preferences
        self.database = local
    }

    func userableTracks(_ isNeedSyncFromRemote: Bool) -> Promise<[Track]> {
        firstly {
            self.database.extractableItems(decode: Track.self)
        }.then { localTracks -> Promise<[Track]> in
            guard isNeedSyncFromRemote || localTracks.isEmpty else {
                return Promise { $0.fulfill(localTracks) }
            }

            return self.remotableTracks(localTracks)
        }
    }

    private func remotableTracks(_ localTracks: [Track]) -> Promise<[Track]> {
        guard let folderId = preferences.serverFolderId else {
            return Promise { resolve in
                resolve.reject(NSError(domain: "Not found folder id in local storage", code: 0, userInfo: nil))
            }
        }

        return firstly {
            self.googleDrive.files(by: .filesByFolder(folderId))
        }.then { value -> Promise<[Track]> in
            let googleFiles = value.files

            let notDownloadedTracks = googleFiles.compactMap { f -> GoogleFile? in
                guard !localTracks.contains(where: { $0.id == f.id }) else {
                    return nil
                }

                return f
            }

            guard !notDownloadedTracks.isEmpty else {
                return Promise { $0.fulfill(localTracks) }
            }

            return firstly {
                self.googleDrive.downloadableTracks(files: notDownloadedTracks).map { localTracks + $0 }
            }.then { newTracks -> Promise<[Track]?> in
                self.database.savingTracks(tracks: newTracks).map { $0 as [Track]? }
            }.then { _ -> Promise<GoogleFile> in
                self.syncabableDatabaseFromRemote()
            }.then { _ -> Promise<[Track]> in
                self.database.extractableItems(decode: Track.self)
            }
        }
    }

    func syncabableDatabaseFromRemote() -> Promise<GoogleFile> {
        firstly {
            when(fulfilled: database.fileStorage.gettableFile(name: "default.realm"), googleDrive.remoteFile(fileName: "default.realm"))
        }.then { (localUrl, response) -> Promise<GoogleFile> in
            guard !response.files.isEmpty, let file = response.files.first else {
                return self.googleDrive.creationableFile(fileUrl: localUrl)
            }

            return self.googleDrive.uploadableFile(by: file.id, fileUrl: localUrl)
        }
    }

    func addPlaylist(_ tracks: [Track], _ playlistName: String) -> Promise<Void> {
        firstly {
            self.database.savePlaylist(tracks, playlistName)
        }
    }
}
