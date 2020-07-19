//
//  GoogleList.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 07/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

struct GoogleFileList: Codable {
    let kind: String?
    let nextPageToken: String? // maybe remove later
    let incompleteSearch: Bool
    let files: [GoogleFile]

    private enum CodingKeys: String, CodingKey {
        case kind
        case nextPageToken
        case incompleteSearch
        case files
    }
}

struct GoogleFile: Codable, Equatable {
    let kind: String?
    let id: String
    let name: String
    let mimeType: String

    private enum CodingKeys: String, CodingKey {
        case kind
        case id
        case name
        case mimeType
    }
}
