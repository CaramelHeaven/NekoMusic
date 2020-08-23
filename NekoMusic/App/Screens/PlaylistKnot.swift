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
        database.extractableItems(decode: Playlist.self)
    }

    // The list has a [removable animation] and thus we need to wait some time before element will be deleted
    func remove(_ playlists: [Playlist]) -> Promise<Void> {
        Promise { resolve in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700)) {
                self.database.remove(items: playlists)
                    .done { resolve.fulfill_() }
                    .catch { resolve.reject($0) }
            }
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
                self.create(data)
            }.store(in: &subscribers)
    }
}
