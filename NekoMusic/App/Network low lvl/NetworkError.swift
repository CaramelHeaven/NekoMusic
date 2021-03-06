//
//  NetworkError.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 30/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Foundation

/**
 Declaration of errors that can throw/return.
 Since this is all about networking, it should pass-through any URLErrors that happen but also add its own
 */
public enum NetworkError: Error {
    /// When network conditions are so bad that after `maxRetries` the request did not succeed.
    case inaccessible

    /// `URLSession` errors are passed-through, handle as appropriate.
    case urlError(URLError)

    /// URLSession returned an `Error` object which is not `URLError`
    case generalError(Swift.Error)

    /// When no `URLResponse` is returned but also no `URLError` or any other `Error` instance.
    case noResponse

    /// When `URLResponse` is not `HTTPURLResponse`.
    case invalidResponseType(URLResponse)

    /// Status code is in `200...299` range, but response body is empty. This can be both valid and invalid, depending on HTTP method and/or specific behavior of the service being called.
    case noResponseData(HTTPURLResponse)

    /// Status code is `400` or higher (except 401 ) thus return the entire `HTTPURLResponse` and `Data` so caller can figure out what happened.
    case endpointError(HTTPURLResponse, Data?)

    /// Expired token
    case expiredToken
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .generalError(error):
            return error.localizedDescription

        case let .urlError(urlError):
            return urlError.localizedDescription

        case .invalidResponseType, .noResponse:
            return NSLocalizedString("Internal error", comment: "")

        case .noResponseData:
            return nil

        case let .endpointError(httpURLResponse, _):
            let s = "\(httpURLResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpURLResponse.statusCode))"
            return s

        case .inaccessible:
            return NSLocalizedString("Service is not accessible", comment: "")
        case .expiredToken:
            return NSLocalizedString("User token has expired", comment: "")
        }
    }

    public var failureReason: String? {
        switch self {
        case let .generalError(error):
            return (error as NSError).localizedFailureReason

        case let .urlError(urlError):
            return (urlError as NSError).localizedFailureReason

        case .noResponse:
            return NSLocalizedString("Request apparently succeeded (no errors) but URLResponse was not received.", comment: "")

        case let .invalidResponseType(response):
            return String(format: NSLocalizedString("Response is not HTTP response.\n\n%@", comment: ""), response)

        case .inaccessible:
            return nil

        case .noResponseData:
            return NSLocalizedString("Request succeeded, no response body received", comment: "")

        case let .endpointError(httpURLResponse, data):
            let s = "\(httpURLResponse.formattedHeaders)\n\n\(data?.utf8StringRepresentation ?? "")"
            return s
        case .expiredToken:
            return String("Response is 401")
        }
    }
}

private extension HTTPURLResponse {
    var formattedHeaders: String {
        return allHeaderFields.map { "\($0.key) : \($0.value)" }.joined(separator: "\n")
    }
}

private extension Data {
    var utf8StringRepresentation: String? {
        guard
            let str = String(data: self, encoding: .utf8)
        else { return nil }

        return str
    }
}

public extension NetworkError {
    ///    Returns `true` if URLRequest should be retried for the given `NetworkError` instance.
    ///
    ///    At the lowest network levels, it makes sense to retry for cases of (possible) temporary outage. Things like timeouts, can't connect to host, network connection lost.
    ///    In mobile context, this can happen as you move through the building or traffic and may not represent serious or more permanent connection issues.
    ///
    ///    Upper layers of the app architecture may build on this to add more specific cases when the request should be retried.
    var shouldRetry: Bool {
        switch self {
        case let .urlError(urlError):
            //    if temporary network issues, retry
            switch urlError.code {
            case URLError.timedOut,
                 URLError.cannotFindHost,
                 URLError.cannotConnectToHost,
                 URLError.networkConnectionLost,
                 URLError.dnsLookupFailed:
                return true
            default:
                break
            }
        case .expiredToken:
            return true
        default:
            break
        }

        return false
    }
}
