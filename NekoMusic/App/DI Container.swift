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
    container.register(.singleton) { Database($0) }
    container.register(.singleton) { MusicPlayer($0) }
    container.register(.singleton) { NSPublisher() }

    // MARK: - Knots

    container.register(.singleton) { () -> TrackListKnot in
        let remote = container.resolve(type: GoogleDrive.self)
        let preferences = container.resolve(type: UserPreferences.self)
        let local = container.resolve(type: Database.self)

        return TrackListKnot(remote, preferences, local)
    }

    // MARK: - View Models

    container.register(.singleton) { () -> PlaylistsViewModel in
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

    container.register(.singleton) { () -> FilesViewModel in
        let remote = container.resolve(type: GoogleDrive.self)
        let preferences = container.resolve(type: UserPreferences.self)

        return FilesViewModel(remote, preferences)
    }

    container.register(.singleton) { SettingsViewModel(preferences: $0) }

    container.register(.singleton) { MainViewModel($0) }

    return container
}()

extension DependencyContainer {
    func resolve<T>(type: T.Type) -> T {
        try! resolve() as T
    }
}
