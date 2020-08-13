//
//  PlaylistsViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 18/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import SwiftUI

final class PlaylistsViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var isPlaylistEnable: Bool = false
    @Published var accentColor: Color = .white

    private let knot: PlaylistKnot
    private let preferences: UserPreferences

    private(set) var subscribers: Set<AnyCancellable> = []

    init(_ knot: PlaylistKnot, _ preferences: UserPreferences) {
        self.knot = knot
        self.preferences = preferences

        self.accentColor = Color(preferences.accentColor)

        subscribed()
        load()
    }

    func load() {
        knot.playlists().done { arr in
            self.playlists = arr
        }.catch { err in
            print("ER: \(err)")
        }
    }

    func select(playlist: Playlist) {
        isPlaylistEnable = true
        reporter.send(.selectPlaylist(playlist))
    }

    func reset() {
        isPlaylistEnable = false
        reporter.send(.resetPlaylist)
    }
}

extension PlaylistsViewModel: ObservableCommands {
    func subscribed() {
        reporter
            .filter { $0 == .playlistDidCreated }
            .sink { _ in
                self.load()
            }
            .store(in: &subscribers)
    }
}
