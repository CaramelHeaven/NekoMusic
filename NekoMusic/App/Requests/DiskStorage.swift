//
//  DiskStorage.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit

final class DiskStorage {
    private let disk = FileManager.default
    lazy var applicationDocumentsDirectory: URL = {
        let documentDirectoryURL = disk.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if !disk.fileExists(atPath: documentDirectoryURL.path) {
            do {
                try disk.createDirectory(at: documentDirectoryURL, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return documentDirectoryURL
            }
        }

        return documentDirectoryURL
    }()

    func writableFile(name: String, data: Data) -> Promise<URL> {
        firstly {
            self.localableUrl(by: name)
        }.then { url -> Guarantee<(Bool, URL)> in
            self.existableFile(by: url).map { ($0, url) }
        }.then { (_, fileUrl) -> Promise<URL> in
            Promise { resolve in
                do {
                    try data.write(to: fileUrl, options: .atomicWrite)
                } catch {
                    print("writableFile: \(error)")
                    resolve.reject(error)
                }

                resolve.fulfill(fileUrl)
            }
        }
    }

    func remove(fileName: String) -> Promise<Void> {
        firstly {
            self.localableUrl(by: fileName)
        }.then { url -> Promise<Void> in
            Promise { resolve in
                do {
                    try self.disk.removeItem(at: url)
                    resolve.fulfill_()
                } catch {
                    print("ERROR: \(error)")
                    resolve.reject(error)
                }
            }
        }
    }

    func gettableFile(name: String) -> Promise<URL> {
        firstly {
            self.localableUrl(by: name)
        }.then { url -> Guarantee<(Bool, URL)> in
            self.existableFile(by: url).map { ($0, url) }
        }.then { (fileExist, fileUrl) -> Promise<URL> in
            Promise { resolve in
                guard fileExist else {
                    return resolve.reject(NSError(domain: "File doesn't exist", code: 0, userInfo: nil))
                }

                return resolve.fulfill(fileUrl)
            }
        }
    }
}

fileprivate extension DiskStorage {
    func localableUrl(by name: String) -> Guarantee<URL> {
        return Guarantee { resolve in
            let url = self.applicationDocumentsDirectory.appendingPathComponent("\(name)")

            resolve(url)
        }
    }

    func existableFile(by url: URL) -> Guarantee<Bool> {
        return Guarantee { resolve in
            resolve(self.disk.fileExists(atPath: url.path))
        }
    }
}
