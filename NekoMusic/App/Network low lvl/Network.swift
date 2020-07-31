//
//  Network.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 24/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Foundation
import PromiseKit

extension URLSession {
    var userSession: UserSession {
        return diContainer.resolve(type: UserSession.self)
    }
}

final class Network {
    private let urlSession: URLSession

    init() {
        self.urlSession = URLSession.shared
    }

    func executableRequest<T: Decodable>(with request: URLRequest, decode: T.Type) -> Promise<T> {
        return Promise { resolve in
            urlSession.perform(request, maxRetries: 3) { temp in
                switch temp {
                case let .success(data):
                    let decoder = JSONDecoder()

                    guard let model = try? decoder.decode(T.self, from: data) else {
                        return resolve.reject(NSError(domain: "Error has happened on decoding state", code: 0, userInfo: nil))
                    }

                    resolve.fulfill(model)
                case let .failure(error):
                    print("Network Error: \(error)")
                    return resolve.reject(error)
                }
            }
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
