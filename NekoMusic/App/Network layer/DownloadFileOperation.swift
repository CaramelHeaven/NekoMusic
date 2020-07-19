//
//  DownloadFileOperation.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 09/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import PromiseKit

final class DownloadFileOperation: AsyncOperation, UrlRequestable {
    private let fileStorage: DiskStorage = {
        try! diContainer.resolve()
    }()

    private let fileName: String
    private let request: URLRequest

    /// Result from operation
    var result: URL?

    init(fileName: String, request: URLRequest) {
        self.fileName = fileName
        self.request = request
    }

    override func main() {
        firstly {
            self.downloadableFile(by: self.request)
        }.then { data in
            self.fileStorage.writableFile(name: self.fileName, data: data)
        }.done { [weak self] url in
            self?.result = url
            self?.finish()
        }.catch { [weak self] e in
            print("er: \(e)")
            self?.finish()
        }
    }
}
