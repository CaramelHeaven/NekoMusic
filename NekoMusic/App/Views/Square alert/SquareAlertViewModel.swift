//
//  SquareAlertViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 02/08/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

class SquareAlertViewModel: ObservableObject {
    enum Cases {
        case downloadingFiles
    }

    @Published var title: String = "Loading ..."

    private let preferences: UserPreferences

    private var downloadedCount: Int?
    private var allCount: Int?
    private(set) var subscribers: Set<AnyCancellable> = []

    init(_ preferences: UserPreferences) {
        self.preferences = preferences

        subscribed()
    }

    private func update(_ typeOfCases: Cases) {
        switch typeOfCases {
        case .downloadingFiles:
            title = "Downloading: \(downloadedCount ?? 0) of \(allCount ?? 0)"
        }
    }
}

extension SquareAlertViewModel: ObservableCommands {
    func subscribed() {
        reporter
            .compactMap { $0.isDownloadedFilesCount }
            .sink { v in
                self.downloadedCount = v
                self.update(.downloadingFiles)
            }
            .store(in: &subscribers)

        reporter
            .compactMap { $0.isAllFilesCount }
            .sink { v in
                self.allCount = v
                self.update(.downloadingFiles)
            }
            .store(in: &subscribers)
    }
}
