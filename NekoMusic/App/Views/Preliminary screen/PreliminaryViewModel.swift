//
//  PreliminaryViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 26/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import PromiseKit
import SwiftUI

class PreliminaryViewModel: ObservableObject {
    @State var preliminaryDone: Bool = false

    private let remote: GoogleDrive
    private let database: Database
    private let preferences: UserPreferences

    init(_ remote: GoogleDrive, _ database: Database, _ preferences: UserPreferences) {
        self.remote = remote
        self.database = database
        self.preferences = preferences

        preload()
    }

    func preload() {
        firstly {
            self.recreateDbIfNeeded(preferences.isAppFirstLaunched)
        }.done { _ in
            reporter.send(.coordinator(.files))
        }.catch { _ in
            print("catch")
        }
    }
}

fileprivate extension PreliminaryViewModel {
    func recreateDbIfNeeded(_ isFirstLaunch: Bool) -> Promise<Void> {
        guard isFirstLaunch else {
            return Promise.value
        }

        return firstly {
            self.remote.remoteFile(fileName: "default.realm")
        }.then { value -> Promise<Void> in
            guard let realmFile = value.files.first else {
                return Promise.value
            }

            return firstly {
                self.remote.loadableFile(realmFile)
            }.then {
                self.database.recreate(fileUrl: $0)
            }
        }
    }
}
