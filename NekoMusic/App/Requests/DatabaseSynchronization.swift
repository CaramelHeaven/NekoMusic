//
//  DatabaseSynchronization.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 02/08/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit

// First implementation, thinking..
class DatabaseSynchronization {
    enum SyncDirection {
        case toRemote
        case fromRemote
    }

    private let remote: GoogleDrive
    private let database: Database

    init(_ remote: GoogleDrive, _ local: Database) {
        self.remote = remote
        self.database = local
    }

    func sync(_ direction: SyncDirection) -> Promise<Void> {
        firstly {
            Promise.value(direction)
        }.then { d -> Promise<Void> in
            switch d {
            case .fromRemote:
                return self.remotelyDownload()
            case .toRemote:
                return self.locallyUpload()
            }
        }
    }

    private func remotelyDownload() -> Promise<Void> {
        firstly {
            remote.remoteFile(fileName: Constants.dbName)
        }.then { response -> Promise<Void> in
            guard let realmFile = response.files.first else {
                return Promise.value
            }

            return firstly {
                self.remote.loadableFile(realmFile)
            }.then {
                self.database.recreate(fileUrl: $0)
            }
        }
    }

    private func locallyUpload() -> Promise<Void> {
        firstly {
            when(fulfilled: database.disk.gettableFile(by: Constants.dbName), remote.remoteFile(fileName: Constants.dbName))
        }.then { (localUrl, response) -> Promise<GoogleFile> in
            guard let localUrl = localUrl else {
                throw NSError(domain: "Local Realm db is not existed", code: 0, userInfo: nil)
            }

            guard !response.files.isEmpty, let file = response.files.first else {
                return self.remote.creationableFile(fileUrl: localUrl)
            }

            return self.remote.uploadableFile(by: file.id, fileUrl: localUrl)
        }.then { _ -> Promise<Void> in
            Promise.value
        }
    }
}
