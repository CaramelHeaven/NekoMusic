//
//  DI Container.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Dip

let diContainer: DependencyContainer = {
    let container = DependencyContainer()

    container.register(.singleton) { UserPreferences() }
    container.register(.singleton) { Network() }
    container.register(.singleton) { GoogleDrive($0, $1) }
    container.register(.singleton) { DiskStorage() }
    container.register(.singleton) { Database($0, $1) }
    container.register(.singleton) { MusicPlayer($0) }
    container.register(.singleton) { UserSession() }

    // MARK: - Knots

    container.register(.singleton) { () -> TrackListKnot in
        let remote = container.resolve(type: GoogleDrive.self)
        let local = container.resolve(type: Database.self)
        let preferences = container.resolve(type: UserPreferences.self)

        return TrackListKnot(remote, local, preferences)
    }

    // MARK: - View Models

    container.register { () -> PreliminaryViewModel in
        let remote = container.resolve(type: GoogleDrive.self)
        let local = container.resolve(type: Database.self)
        let preferences = container.resolve(type: UserPreferences.self)

        return PreliminaryViewModel(remote, local, preferences)
    }

    container.register { () -> PlaylistsViewModel in
        let local = container.resolve(type: Database.self)
        let preferences = container.resolve(type: UserPreferences.self)

        return PlaylistsViewModel(local, preferences)
    }

    container.register(.singleton) { () -> TrackListViewModel in
        let knot = container.resolve(type: TrackListKnot.self)
        let music = container.resolve(type: MusicPlayer.self)
        let preferences = container.resolve(type: UserPreferences.self)

        return TrackListViewModel(knot, music, preferences)
    }

    container.register { () -> FilesViewModel in
        let remote = container.resolve(type: GoogleDrive.self)
        let preferences = container.resolve(type: UserPreferences.self)

        return FilesViewModel(remote, preferences)
    }

    container.register { SettingsViewModel(preferences: $0) }

    container.register { MainViewModel() }

    return container
}()

extension DependencyContainer {
    func resolve<T>(type: T.Type) -> T {
        try! resolve() as T
    }
}
