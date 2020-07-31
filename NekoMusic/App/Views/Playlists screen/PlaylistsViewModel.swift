//
//  PlaylistsViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 18/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import SwiftUI

final class PlaylistsViewModel: ObservableObject, ObservableCommands {
    @Published var playlists: [Playlist] = []
    @Published var isPlaylistEnable: Bool = false
    @Published var accentColor: Color = .white

    private let local: Database
    private let preferences: UserPreferences

    var subscribers: Set<AnyCancellable> = []

    init(_ local: Database, _ preferences: UserPreferences) {
        self.local = local
        self.preferences = preferences

        self.accentColor = Color(preferences.accentColor)

        subscribed()
//        load()
    }

    func subscribed() {
        reporter
            .filter { $0 == .addedNewablePlaylist }
            .sink { [weak self] _ in
                self?.load()
            }
            .store(in: &subscribers)
    }

    func load() {
        local.extractableItems(decode: Playlist.self).done { [weak self] playlists in
            self?.playlists = playlists
        }.catch {
            print("ER: \($0)")
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
