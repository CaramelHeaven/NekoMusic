//
//  ImportFoldersViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 25/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

final class FilesViewModel: ObservableObject {
    @Published var files: [GoogleFile] = []
    @Published var selectedFile: GoogleFile?

    private let remote: GoogleDrive
    private let preferences: UserPreferences

    init(_ remote: GoogleDrive, _ preferences: UserPreferences) {
        self.remote = remote
        self.preferences = preferences

        show()
    }

    func selected(rowIndex: Int) {
        guard files.indices.contains(rowIndex) else { return }

        selectedFile = files[rowIndex]
    }

    func save() {
        preferences.set(key: .serverFolderId, value: selectedFile?.id)

        // delay is needed to smoothly move the screen after closing the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            publisher.send(.userChoosedFolder)
        }
    }
}

fileprivate extension FilesViewModel {
    func show() {
        remote.listOfFiles().done { [weak self] value in
            self?.files = value.files
        }.catch { err in
            print("FilesViewModel ER: \(err)")
        }
    }
}
