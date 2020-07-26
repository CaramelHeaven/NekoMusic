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
            self.localUrl(by: name)
        }.then { url -> Promise<URL> in
            Promise { resolve in
                do {
                    try data.write(to: url, options: .atomicWrite)
                } catch {
                    throw error
                }

                resolve.fulfill(url)
            }
        }
    }

    func remove(fileUrl: URL) -> Promise<Void> {
        Promise { resolve in
            do {
                try self.disk.removeItem(at: fileUrl)
                resolve.fulfill_()
            } catch {
                throw error
            }
        }
    }

    func remove(fileName: String) -> Promise<Void> {
        firstly {
            self.gettableFile(by: fileName)
        }.then { url -> Promise<Void> in
            Promise { resolve in
                guard let url = url else { return resolve.fulfill_() }

                do {
                    try self.disk.removeItem(at: url)
                    resolve.fulfill_()
                } catch {
                    throw error
                }
            }
        }
    }

    func gettableFile(by name: String) -> Guarantee<URL?> {
        firstly {
            self.localUrl(by: name)
        }.then { url -> Guarantee<(URL, Bool)> in
            Guarantee.value(self.disk.fileExists(atPath: url.path))
                .map { (url, $0) }
        }.then { (fileUrl, isExist) -> Guarantee<URL?> in
            Guarantee.value(isExist ? fileUrl : nil)
        }
    }

    /// The same as gettableFile but without promise for the sake of flexibility
    func gettableFile(name: String) -> URL? {
        let url = applicationDocumentsDirectory.appendingPathComponent("\(name)")
        guard disk.fileExists(atPath: url.path) else {
            return nil
        }

        return url
    }

    func existableFile(by name: String) -> Guarantee<Bool> {
        firstly {
            self.gettableFile(by: name)
        }.then { url -> Guarantee<Bool> in
            Guarantee.value(url != nil)
        }
    }

    func localUrl(by name: String) -> Guarantee<URL> {
        Guarantee.value(applicationDocumentsDirectory.appendingPathComponent("\(name)"))
    }
}
