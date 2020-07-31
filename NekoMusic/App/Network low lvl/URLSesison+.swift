//
//  URLSesison+.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 30/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Foundation

/*
 Retrieved from https://github.com/radianttap/Alley
 Slightly changed some functions according to my wishes
 */
public extension URLSession {
    ///    Default number of retries to attempt on each `URLRequest` instance. To customize, supply desired value to `perform()`
    static var maximumNumberOfRetries: Int = 10

    ///    Output types
    typealias DataResult = Result<Data, NetworkError>
    // I dont like this
    typealias Callback = (DataResult) -> Void

    /// Executes given URLRequest instance, possibly retrying the said number of times. Through `callback` returns either `Data` from the response or `NetworkError` instance.
    /// If any authentication needs to be done, it's handled internally by this methods and its derivatives.
    /// - Parameters:
    ///   - urlRequest: URLRequest instance to execute.
    ///   - maxRetries: Number of automatic retries (default is 10).
    ///   - allowEmptyData: Should empty response `Data` be treated as failure (this is default) even if no other errors are returned by URLSession. Default is `false`.
    ///   - callback: Closure to return the result of the request's execution.
    func perform(_ urlRequest: URLRequest, maxRetries: Int = URLSession.maximumNumberOfRetries, allowEmptyData: Bool = false, callback: @escaping Callback) {
        if maxRetries <= 0 {
            fatalError("maxRetries must be 1 or larger.")
        }

        let networkRequest = NetworkRequest(urlRequest, 0, maxRetries, allowEmptyData, callback)
        authenticate(networkRequest)
    }
}

private extension URLSession {
    ///    Helper type which groups `URLRequest` (input), `Callback` from the caller (output)
    ///    along with helpful processing properties, like number of retries.
    typealias NetworkRequest = (urlRequest: URLRequest, currentRetries: Int,
                                maxRetries: Int, allowEmptyData: Bool, callback: Callback)

    ///    Extra-step where `URLRequest`'s authorization should be handled, before actually performing the URLRequest in `execute()`
    func authenticate(_ request: NetworkRequest, dueTo error: NetworkError? = nil) {
        let currentRetries = request.currentRetries
        let max = request.maxRetries
        let callback = request.callback

        if currentRetries >= max {
            callback(.failure(.inaccessible))
        }

        guard let error = error, case NetworkError.expiredToken = error else {
            execute(request)
            return
        }

        // If multiple requests has failed and come here we'll get token more than one.
        userSession.user?.authentication.getTokensWithHandler({ [unowned self] auth, err in
            guard let auth = auth, err == nil else {
                callback(.failure(.generalError(err!)))
                return
            }
            var newRequest = request
            newRequest.urlRequest.setValue("Bearer \(auth.accessToken!)", forHTTPHeaderField: "Authorization")
            self.userSession.accessToken = auth.accessToken

            self.execute(newRequest)
        })
    }

    ///    Creates the instance of `URLSessionDataTask`, performs it then lightly processes the response before calling `validate`.
    func execute(_ networkRequest: NetworkRequest) {
        let urlRequest = networkRequest.urlRequest

        let task = dataTask(with: urlRequest) { [unowned self] data, urlResponse, error in

            let dataResult = self.process(data, urlResponse, error, for: networkRequest)
            self.validate(dataResult, for: networkRequest)
        }

        task.resume()
    }

    ///    Process results of `URLSessionDataTask` and converts it into `DataResult` instance
    func process(_ data: Data?, _ urlResponse: URLResponse?, _ error: Error?, for networkRequest: NetworkRequest) -> DataResult {
        let allowEmptyData = networkRequest.allowEmptyData

        if let urlError = error as? URLError {
            return .failure(NetworkError.urlError(urlError))

        } else if let otherError = error {
            return .failure(NetworkError.generalError(otherError))
        }

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            if let urlResponse = urlResponse {
                return .failure(NetworkError.invalidResponseType(urlResponse))
            } else {
                return .failure(NetworkError.noResponse)
            }
        }

        if httpURLResponse.statusCode == 401 {
            return .failure(.expiredToken)
        }

        if httpURLResponse.statusCode >= 400 {
            return .failure(NetworkError.endpointError(httpURLResponse, data))
        }

        guard let data = data, !data.isEmpty else {
            if allowEmptyData {
                return .success(Data())
            }

            return .failure(NetworkError.noResponseData(httpURLResponse))
        }

        return .success(data)
    }

    ///    Checks the result of URLSessionDataTask and if there were errors, should the URLRequest be retried.
    func validate(_ result: DataResult, for networkRequest: NetworkRequest) {
        let callback = networkRequest.callback

        switch result {
        case .success:
            break

        case let .failure(err):
            switch err {
            case .inaccessible:
                //    too many failed network calls
                break

            default:
                if err.shouldRetry {
                    var newRequest = networkRequest
                    newRequest.currentRetries += 1
                    //    try again, going through authentication again, (since it's quite possible that Auth token or whatever has expired)
                    authenticate(newRequest, dueTo: err)
                    return
                }
            }
        }

        callback(result)
    }
}
