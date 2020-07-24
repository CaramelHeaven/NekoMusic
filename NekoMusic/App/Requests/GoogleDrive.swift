//
//  GoogleDriveRequests.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit

final class GoogleDrive: UrlRequestable {
    private let network: Network
    private let disk: DiskStorage

    // Used for serial files downloading in dispatch queue
    private let semaphore = DispatchSemaphore(value: 1)
    private let queue = DispatchQueue(label: "Queue.GoogleDrive")
    private let pageSize = 1000

    init(_ network: Network, _ disk: DiskStorage) {
        self.network = network
        self.disk = disk
    }

    /// Get files by query
    func files(by query: ApiQuery) -> Promise<GoogleFileList> {
        let urlStr = "https://www.googleapis.com/drive/v3/files?pageSize=\(pageSize)&\(query.result)"

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.network.executableRequest(with: $0, decode: GoogleFileList.self)
        }
    }

    /// Find remote file
    func remoteFile(fileName: String) -> Promise<GoogleFileList> {
        let urlStr = "https://www.googleapis.com/drive/v3/files?q=name contains \"\(fileName)\""

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.network.executableRequest(with: $0, decode: GoogleFileList.self)
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
            self.network.executableRequest(with: $0, decode: GoogleFile.self)
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
            self.network.executableRequest(with: $0, decode: GoogleFile.self)
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
            self.network.executableRequest(with: $0, decode: GoogleFile.self)
        }
    }

    /// Serial downloading files from google drive to local storage
    /// - Parameter files: google files which we got from promises chaining
    /// - Returns: array of Tracks which we'll write to realm in the knot layer
    func downloadableTracks(files: [GoogleFile]) -> Promise<[Track]> {
        return Promise { resolve in
            publisher.send(.allFilesCount(files.count))

            let group = DispatchGroup()
            var tracks = [Track]()
            var count = 0

            files.indices.forEach { index in
                queue.async { [weak self] in
                    guard let self = self else { return }

                    group.enter()
                    self.semaphore.wait()

                    self.loadableFile(files[index]).done { track in
                        tracks.append(track)

                        DispatchQueue.main.async {
                            count += 1
                            publisher.send(.downloadedFilesCount(count))
                        }

                        self.semaphore.signal()
                        group.leave()
                    }.catch { err in
                        print("ER \(err)")
                        fatalError()
                    }
                }
            }

            group.notify(queue: .main) {
                resolve.fulfill(tracks)
            }
        }
    }
}

// MARK: - API queries

extension GoogleDrive {
    enum ApiQuery {
        case listOfFolders
        case filesByFolder(String)

        var result: String {
            switch self {
            case .listOfFolders:
                return "q=mimeType = \"application/vnd.google-apps.folder\""
            case let .filesByFolder(id):
                return "q=\"\(id)\" in parents"
            }
        }
    }
}

fileprivate extension GoogleDrive {
    func loadableFile(_ file: GoogleFile) -> Promise<Track> {
        let urlStr = "https://www.googleapis.com/drive/v3/files/\(file.id)?alt=media"

        return firstly {
            self.buildableUrl(by: urlStr)
        }.then {
            self.network.executableRequest(with: $0)
        }.then { data in
            self.disk.writableFile(name: file.name, data: data)
        }.then { _ in
            Promise.value(Track(id: UUID().uuidString, name: file.name))
        }
    }
}
