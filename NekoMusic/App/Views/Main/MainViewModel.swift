//
//  MainControlViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 08/06/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine

class MainViewModel: ObservableObject {
    @Published var filesImportNeeded: Bool

    var subscribers: Set<AnyCancellable> = []

    private let preferences: UserPreferences

    init(_ preferences: UserPreferences) {
        self.preferences = preferences
        self.filesImportNeeded = preferences.serverFolderId == nil

        subscribed()
    }
}

extension MainViewModel: ObservableCommands {
    func subscribed() {
        publisher
            .filter { $0 == .userChoosedFolder }
            .sink { [weak self] _ in
                self?.filesImportNeeded = false
            }
            .store(in: &subscribers)
    }
}
