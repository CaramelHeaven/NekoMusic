//
//  GoogleDriveRequests.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit

final class GoogleDrive: UrlRequestable {
    private let pageSize = 1000

    private let downloadFileQueue = OperationQueue()

    /// Get list of folders from user cloud 'disk'
    func listOfFiles() -> Promise<GoogleFileList> {
        let urlStr = "https://www.googleapis.com/drive/v3/files?pageSize=\(pageSize)&q=mimeType = \"application/vnd.google-apps.folder\""

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.executableRequest(with: $0, decode: GoogleFileList.self)
        }
    }

    /// Get files by folder id for future downloading
    func files(by folderId: String) -> Promise<GoogleFileList> {
        let urlStr = "https://www.googleapis.com/drive/v3/files?pageSize=\(pageSize)&q=\"\(folderId)\" in parents"

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.executableRequest(with: $0, decode: GoogleFileList.self)
        }
    }

    /// Find remote file
    func remoteFile(fileName: String) -> Promise<GoogleFileList> {
        let urlStr = "https://www.googleapis.com/drive/v3/files?q=name contains \"\(fileName)\""

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.executableRequest(with: $0, decode: GoogleFileList.self)
        }
    }

    /// Create file with multipart
    /// - Parameter fileUrl: local URL for converting to Data
    func creationableFile(fileUrl: URL) -> Promise<GoogleFile> {
        let urlStr = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"

        let data = try! Data(contentsOf: fileUrl)
        let json: [String: String] = [
            "name": "test.realm",
            "mimeType": "application/octet-stream",
        ]

        return firstly {
            self.buildableMultipartUrl(by: urlStr, parameters: json, method: .post, data: data)
        }.then {
            self.executableRequest(with: $0, decode: GoogleFile.self)
        }
    }

    /// Create simple file without data
    func creationableFile(fileName: String) -> Promise<GoogleFile> {
        let urlStr = "https://www.googleapis.com/drive/v3/files"
        let parameters: [String: Any] = [
            "name": fileName,
        ]
        let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

        return firstly {
            self.buildableUrl(by: urlStr, method: .post, data: data)
        }.then {
            self.executableRequest(with: $0, decode: GoogleFile.self)
        }
    }

    /// Upload file with multipart by file id
    /// - Parameters:
    ///   - fileId: google file id
    ///   - fileUrl: local file url
    func uploadableFile(by fileId: String, fileUrl: URL) -> Promise<GoogleFile> {
        let urlStr = "https://www.googleapis.com/upload/drive/v3/files/\(fileId)/?uploadType=multipart"

        let data = try! Data(contentsOf: fileUrl)
        let json: [String: String] = [
            "name": "test.realm",
            "mimeType": "application/octet-stream",
        ]

        return firstly {
            self.buildableMultipartUrl(by: urlStr, parameters: json, method: .post, data: data)
        }.then {
            self.executableRequest(with: $0, decode: GoogleFile.self)
        }
    }
}

// MARK: - Remote

extension GoogleDrive {
    func getFile<T: Decodable>(fileId: String, decode: T.Type) -> Promise<T> {
        let urlStr = "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media"

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.executableRequest(with: $0, decode: T.self)
        }
    }

    // need to extract this func to new class
    func downloadTrackFiles(files: [GoogleFile]) -> Promise<[Track]> {
        publisher.send(.allFilesCount(files.count))

        return Promise { resolve in
            var tracks = [Track]()
            let group = DispatchGroup()

            let operations = files.indices.compactMap { index -> DownloadFileOperation? in
                let urlStr = "https://www.googleapis.com/drive/v3/files/\(files[index].id)?alt=media"
                guard let request = self.makeURLRequest(by: urlStr) else {
                    return nil
                }

                let op = DownloadFileOperation(fileName: files[index].name, request: request)
                op.completionBlock = {
                    guard let url = op.result else {
                        return
                    }

                    let track = Track(id: files[index].id, localStringUrl: url.absoluteString, name: files[index].name)

                    tracks.append(track)
                    group.leave()

                    DispatchQueue.main.async {
                        publisher.send(.downloadedFilesCount(index + 1))
                    }
                }

                return op
            }

            // Set sequence work
            if operations.count > 1 {
                (1...operations.count - 1).forEach { index in
                    operations[index].addDependency(operations[index - 1])
                }
            }

            operations.forEach {
                group.enter()
                self.downloadFileQueue.addOperation($0)
            }

            // addBarrierBlock doesnt wait [last] operation completion block
            group.notify(queue: .main) {
                resolve.fulfill(tracks)
            }
        }
    }
}
