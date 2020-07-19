//
//  Extensions.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 18/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == String {
    /// Convert dict-json to str
    /// - Returns: String, example: {"name":"test.w","mimeType":"application/octet-stream"}
    func toJSON() -> String {
        reduce("{") {
            $0 + "\"\($1.key)\":\"\($1.value)\","
        }
        .dropLast()
        .toString()
        .appending("}")
    }
}

extension Array where Element == Character {
    func toString() -> String {
        String(self)
    }
}

extension Data {
    /// Append string to Data
    ///
    /// Rather than littering my code with calls to `data(using: .utf8)` to convert `String` values to `Data`, this wraps it in a nice convenient little extension to Data. This defaults to converting using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `Data`.

    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
