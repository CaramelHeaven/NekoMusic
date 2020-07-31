//
//  MusicPlayer.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 13/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import AVFoundation
import Combine
import MediaPlayer
import PromiseKit

final class MusicPlayer: NSObject {
    enum PlayingState: Equatable {
        case playing(Track, Bool = false), stop(Track), none
    }

    private let disk: DiskStorage

    var executingTrack: Track?
    var playingState: PlayingState = .none

    private var avPlayer: AVAudioPlayer?
    private var playbackTimer: ResumableTimer?

    init(_ disk: DiskStorage) {
        self.disk = disk
    }

    func playlableTrack(_ track: Track) -> Promise<PlayingState> {
        firstly {
            self.playlableState(track: track)
        }.then {
            self.actionableAudio(state: $0)
        }.then {
            self.observableTime(state: $0)
        }
    }
}

extension MusicPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }

        reporter.send(.trackDidFinished)
    }
}

extension MusicPlayer: ResumableTimerDelegate {
    func emitter() {
        guard let avPlayer = self.avPlayer else { return }

        let progress = avPlayer.currentTime / avPlayer.duration
        guard progress != 0 else { return }

        reporter.send(.passedTrackTime(progress))
    }
}

fileprivate extension MusicPlayer {
    func observableTime(state: PlayingState) -> Promise<PlayingState> {
        Promise { resolve in
            switch state {
            case let .playing(_, isPaused):
                guard !isPaused else {
                    self.playbackTimer?.resume()
                    return resolve.fulfill(state)
                }

                self.playbackTimer = ResumableTimer(interval: 0.5)
                self.playbackTimer?.delegate = self
                self.playbackTimer?.isRepeatable = true

                self.playbackTimer?.start()
            case .stop:
                self.playbackTimer?.pause()
            default:
                fatalError()
            }

            resolve.fulfill(state)
        }
    }

    func playlableState(track: Track) -> Promise<PlayingState> {
        Promise { resolve in
            switch playingState {
            case let .playing(currentTrack, _):
                self.playingState = track == currentTrack ? .stop(track) : .playing(track)
            case let .stop(currentTrack):
                let isNeedToResume: Bool = track == currentTrack

                self.playingState = self.playingState == .stop(currentTrack) ? PlayingState.playing(track, isNeedToResume) : .stop(currentTrack)
            case .none:
                self.playingState = .playing(track)
            }

            resolve.fulfill(playingState)
        }
    }

    func actionableAudio(state: PlayingState) -> Promise<PlayingState> {
        Promise { resolve in
            switch state {
            case let .playing(track, isNeedToResume):
                guard !isNeedToResume else {
                    self.avPlayer?.play()
                    return resolve.fulfill(state)
                }

                self.avPlayer = try AVAudioPlayer(contentsOf: track.localUrl, fileTypeHint: AVFileType.mp3.rawValue)
                self.avPlayer?.delegate = self

                self.avPlayer?.play()
            case .stop:
                self.avPlayer?.pause()
            case .none:
                fatalError()
            }

            resolve.fulfill(state)
        }
    }
}

protocol ResumableTimerDelegate: AnyObject {
    func emitter()
}

final class ResumableTimer: NSObject {
    private var timer: Timer? = Timer()

    private var startTime: TimeInterval?
    private var elapsedTime: TimeInterval?

    weak var delegate: ResumableTimerDelegate?

    init(interval: Double) {
        self.interval = interval
    }

    var isRepeatable: Bool = false
    var interval: Double = 0.0

    func isPaused() -> Bool {
        guard let timer = timer else { return false }
        return !timer.isValid
    }

    func start() {
        runTimer(interval: interval)
    }

    func pause() {
        elapsedTime = Date.timeIntervalSinceReferenceDate - (startTime ?? 0.0)
        timer?.invalidate()
    }

    func resume() {
        interval -= elapsedTime ?? 0.0
        runTimer(interval: interval)
    }

    func invalidate() {
        timer?.invalidate()
    }

    func reset() {
        startTime = Date.timeIntervalSinceReferenceDate
        runTimer(interval: interval)
    }

    private func runTimer(interval: Double) {
        startTime = Date.timeIntervalSinceReferenceDate

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: isRepeatable) { [weak self] _ in
            self?.delegate?.emitter()
        }
    }
}
