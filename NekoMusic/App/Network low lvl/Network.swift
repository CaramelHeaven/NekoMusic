//
//  Network.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 24/07/2020.
//  Copyright © 2020 Sergey Fominov. All rights reserved.
//

import Foundation
import PromiseKit

final class Network {
    func executableRequest<T: Decodable>(with request: URLRequest, decode: T.Type) -> Promise<T> {
        return Promise { resolve in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data, err == nil else {
                    return resolve.reject(err!)
                }
                let decoder = JSONDecoder()

                guard let model = try? decoder.decode(T.self, from: data) else {
                    return resolve.reject(NSError(domain: "Error has happened on decoding state", code: 0, userInfo: nil))
                }

                resolve.fulfill(model)
            }

            task.resume()
        }
    }

    func executableRequest(with request: URLRequest) -> Promise<Data> {
        return Promise { resolver in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data, err == nil else {
                    return resolver.reject(err!)
                }

                resolver.fulfill(data)
            }

            task.resume()
        }
    }
}
