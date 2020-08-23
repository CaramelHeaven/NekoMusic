//
//  Publishers.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 18/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import SwiftUI

protocol ObservableCommands {
    var subscribers: Set<AnyCancellable> { get }

    func subscribed()
}

let reporter: PassthroughSubject<PublishValue, Never> = PassthroughSubject()

enum CoordinatorView {
    case files
    case main
}

enum PublishValue: Equatable {
    case coordinator(CoordinatorView)

    // MARK: - commands

    case selectPlaylist(Playlist)
    case resetPlaylist
    case createPlaylist(DataPlaylist)
    case playlistDidCreated
    case playlistDidRemoved

    case settingsColor(Color)

    case trackDidFinished
    case passedTrackTime(Double)

    case downloadedFilesCount(Int)
    case allFilesCount(Int)

    func extractable<T>(by type: T.Type) -> T? {
        switch self {
        case let .selectPlaylist(p):
            return p as? T
        case let .settingsColor(c):
            return c as? T
        case let .passedTrackTime(d):
            return d as? T
        case let .downloadedFilesCount(i), let .allFilesCount(i):
            return i as? T
        case let .createPlaylist(v):
            return v as? T
        case let .coordinator(v):
            return v as? T
        default:
            return nil
        }
    }
}

extension PublishValue {
    var isPassedTrackTime: Bool {
        guard case PublishValue.passedTrackTime = self else { return false }
        return true
    }

    var isDownloadedFilesCount: Int? {
        guard case PublishValue.downloadedFilesCount = self else { return nil }
        return extractable(by: Int.self)
    }

    var isAllFilesCount: Int? {
        guard case PublishValue.allFilesCount = self else { return nil }
        return extractable(by: Int.self)
    }
}

// MARK: - Models

struct DataPlaylist: Equatable {
    let name: String
    let tracks: [Track]
}
