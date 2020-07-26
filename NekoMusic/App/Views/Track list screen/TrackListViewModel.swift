//
//  TrackListViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import PromiseKit
import SwiftUI

final class TrackListViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var selectedTracks: [Track] = []
    @Published var downloadedCount: Int = 0
    @Published var tracksCount: Int = 0
    @Published var isTrackPlaylable: Bool = false
    @Published var isPlaylistEnable: Bool = false
    @Published var playingMusicName: String = "..Not playing.."
    @Published var currentTrack: Track?
    @Published var accentColor: Color = .white
    @Published var isError: Bool = false

    private var nsPublisher: NSPublisher {
        diContainer.resolve(type: NSPublisher.self)
    }

    private let knot: TrackListKnot
    private let music: MusicPlayer
    private let preferences: UserPreferences

    /// Cached tracks for reset filtered playlist data
    private var cachedMainTracks: [Track]?
    private var passedTrackTimeValue: Double?
    var subscribers: Set<AnyCancellable> = []

    init(_ knot: TrackListKnot, _ music: MusicPlayer, _ preferences: UserPreferences) {
        self.knot = knot
        self.music = music
        self.preferences = preferences

        self.accentColor = Color(preferences.accentColor)

        subscribed()
        load()
    }

    func play(_ selectedTrack: Track?) {
        // think about this damn
        if let track = selectedTrack {
            currentTrack = track
        }

        guard let playingTrack = currentTrack else {
            return
        }

        music.playlableTrack(playingTrack).done { state in
            switch state {
            case let .playing(value, _):
                self.isTrackPlaylable = true
                self.playingMusicName = value.uiName
            case .stop:
                self.isTrackPlaylable = false
            case .none:
                fatalError()
            }
        }.catch { err in
            print("ER: \(err)")
        }
    }

    func playNext(direction: Array<Track>.TrackDirection) {
        guard let playingTrack = currentTrack else { return }

        let track = tracks.getTrack(current: playingTrack, direction: direction)
        play(track)
    }

    func doublePressed(on track: Track) {
        guard !track.isTrackSelected else {
            selectedTracks.append(track)
            return
        }

        guard let i = selectedTracks.firstIndex(of: track) else {
            return
        }
        selectedTracks.remove(at: i)
    }
}

// MARK: - Playlists actions

fileprivate extension TrackListViewModel {
    func selectedPlaylist(playlist: Playlist) {
        tracks = cachedMainTracks?.filter { t -> Bool in
            t.playlists.contains { $0.name == playlist.name }
        } ?? []

        isPlaylistEnable = true
    }

    func reset() {
        tracks = cachedMainTracks ?? []
        isPlaylistEnable = false
    }
}

// MARK: - Knotting

extension TrackListViewModel {
    func load(isNeedSyncFromRemote: Bool = false) {
        knot.userableTracks(isNeedSyncFromRemote).done { [weak self] tracks in
            guard let self = self else { return }

            self.tracks = tracks
            self.cachedMainTracks = tracks
        }.catch {
            print("showUserTracks ER: \($0)")
        }
    }

    func addPlaylist(with tracks: [Track], playlistName: String) {
        knot.addPlaylist(tracks, playlistName).done { [weak self] _ in
            self?.selectedTracks.forEach { $0.isTrackSelected = false }
            self?.selectedTracks.removeAll()

            publisher.send(.addedNewablePlaylist)
        }.catch {
            print("ER: \($0)")
        }
    }
}

// MARK: - Subscribers

extension TrackListViewModel: ObservableCommands {
    func subscribed() {
        publisher
            .filter { $0 == .resetPlaylist }
            .sink { [weak self] _ in
                self?.reset()
            }
            .store(in: &subscribers)

        publisher
            .filter { $0.isSelectedPlaylist }
            .compactMap { $0.valuable(by: Playlist.self) }
            .sink { [weak self] p in
                self?.selectedPlaylist(playlist: p)
            }
            .store(in: &subscribers)

        publisher
            .filter { $0.isSettingsColor }
            .compactMap { $0.valuable(by: Color.self) }
            .sink { [weak self] c in
                self?.accentColor = c
            }
            .store(in: &subscribers)

        publisher
            .filter { $0.isDownloadedFilesCount }
            .compactMap { $0.valuable(by: Int.self) }
            .sink { [weak self] v in
                self?.downloadedCount = v
            }
            .store(in: &subscribers)

        publisher
            .filter { $0.isAllFilesCount }
            .compactMap { $0.valuable(by: Int.self) }
            .sink { [weak self] v in
                self?.tracksCount = v
            }
            .store(in: &subscribers)

        publisher
            .filter { $0 == .userChoosedFolder }
            .sink { [weak self] _ in
                self?.load()
            }
            .store(in: &subscribers)

        nsPublisher.sub
            .filter { $0.isPassedTrackTime }
            .compactMap { $0.valuable(by: Double.self) }
            .sink { [weak self] v in
                self?.passedTrackTimeValue = v
            }
            .store(in: &subscribers)

        nsPublisher.sub
            .filter { $0 == .trackDidFinished }
            .sink { [weak self] _ in
                self?.playNext(direction: .next)
            }
            .store(in: &subscribers)
    }
}

// MARK: - Additional Views

extension TrackListViewModel {
    func dialog() {
        guard !selectedTracks.isEmpty else { return }

        let alertController = UIAlertController(title: nil, message: "Write a playlist name", preferredStyle: .alert)

        alertController.addTextField { (textField: UITextField!) -> Void in
            textField.placeholder = "Playist name"
        }

        let saveAction = UIAlertAction(title: "Upload", style: .default, handler: { [weak self] _ in
            guard let self = self, let name = alertController.textFields?.first?.text else { return }

            self.addPlaylist(with: self.selectedTracks, playlistName: name)
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
