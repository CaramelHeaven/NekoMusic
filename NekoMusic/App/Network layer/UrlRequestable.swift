//
//  NetworkRequestable.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 07/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import MobileCoreServices
import PromiseKit

enum HttpMethod: String {
    case patch, post, delete, get

    var raw: String {
        return rawValue.uppercased()
    }
}

protocol UrlRequestable {
}

extension UrlRequestable {
    func executableRequest<T: Decodable>(with request: URLRequest, decode: T.Type) -> Promise<T> {
        return Promise { resolve in
            let task = URLSession.shared.dataTask(with: request) { data, _, err in
                guard let data = data, err == nil else {
                    return resolve.reject(err!)
                }
                let decoder = JSONDecoder()

                guard let model = try? decoder.decode(T.self, from: data) else {
                    return resolve.reject(NSError(domain: "Error happened on decoding state", code: 0, userInfo: nil))
                }

                resolve.fulfill(model)
            }

            task.resume()
        }
    }

    func downloadableFile(by request: URLRequest) -> Promise<Data> {
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

    /// Create simple request
    func buildableUrl(by urlStr: String, method: HttpMethod? = nil, data: Data? = nil) -> Promise<URLRequest> {
        Promise { resolve in
            guard let request = self.makeURLRequest(by: urlStr, method: method, data: data) else {
                return resolve.reject(NSError(domain: "Request is nil", code: 0, userInfo: nil))
            }

            resolve.fulfill(request)
        }
    }

    // think
    func makeURLRequest(by urlStr: String, method: HttpMethod? = nil, data: Data? = nil) -> URLRequest? {
        guard let str = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let url = URL(string: str) else {
            return nil
        }

        var request = URLRequest(url: url)

        request.setValue("Bearer \(UserSession.shared.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.httpMethod = method?.raw
        request.httpBody = data

        return request
    }

    /// Create request with multipart data
    func buildableMultipartUrl(by urlStr: String, parameters: [String: String], method: HttpMethod = .post, data: Data) -> Promise<URLRequest> {
        Promise { resolve in
            guard let str = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                let url = URL(string: str) else {
                return resolve.reject(NSError(domain: "Request is nil", code: 0, userInfo: nil))
            }
            var request = URLRequest(url: url)

            let boundary = boundaryString()

            request.setValue("Bearer \(UserSession.shared.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            request.httpMethod = method.raw
            request.httpBody = multipartBody(parameters, boundary, data)

            resolve.fulfill(request)
        }
    }
}

// MARK: - Multipart

fileprivate extension UrlRequestable {
    func multipartBody(_ parameters: [String: String], _ boundary: String, _ data: Data) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\"\r\n")
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n")

        body.append(parameters.toJSON())
        body.append("\r\n--\(boundary)\r\n")

        body.append("Content-Disposition: form-data; name=\"\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")

        body.append("dasdasddadasksladkadadjiadhasiud 222")
        body.append(data)
        body.append("\r\n--\(boundary)--")

        return body
    }

    func boundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
}
