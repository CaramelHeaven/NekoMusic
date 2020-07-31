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

    func select(rowIndex: Int) {
        guard files.indices.contains(rowIndex) else { return }

        selectedFile = files[rowIndex]
    }

    func save() {
        preferences.set(key: .serverFolderId, value: selectedFile?.id)
        reporter.send(.coordinator(.main))
    }
}

fileprivate extension FilesViewModel {
    func show() {
        remote.files(by: .listOfFolders).done { value in
            self.files = value.files
        }.catch { _ in
            fatalError()
        }
    }
}
