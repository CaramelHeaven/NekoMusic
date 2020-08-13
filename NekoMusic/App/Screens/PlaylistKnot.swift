//
//  PlaylistKnot.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 11/08/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import Foundation
import PromiseKit

final class PlaylistKnot {
    private let database: Database
    private(set) var subscribers: Set<AnyCancellable> = []

    init(_ database: Database) {
        self.database = database

        subscribed()
    }

    func playlists() -> Promise<[Playlist]> {
        firstly {
            database.extractableItems(decode: Playlist.self)
        }
    }

    private func create(_ data: DataPlaylist) {
        database.createPlaylist(data: data).done { _ in
            reporter.send(.playlistDidCreated)
        }.catch { err in
            print("ER: \(err)")
        }
    }
}

extension PlaylistKnot: ObservableCommands {
    func subscribed() {
        reporter
            .compactMap { $0.extractable(by: DataPlaylist.self) }
            .sink { data in
                print("here: \(data)")
                self.create(data)
            }.store(in: &subscribers)
    }
}
