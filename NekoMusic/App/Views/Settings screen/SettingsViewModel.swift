//
//  SettingsViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 23/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var selectedAccentIndex: Int?
    @Published var accentColor: [UIColor] = [
        UIColor.systemRed, UIColor.systemPink, UIColor.systemOrange,
        UIColor.systemYellow, UIColor.systemPurple, UIColor.systemTeal,
        UIColor.systemIndigo, UIColor.systemBlue, UIColor.systemGreen,
    ]

    private let preferences: UserPreferences

    init(preferences: UserPreferences) {
        self.preferences = preferences

        self.selectedAccentIndex = cachableColorIndex()
    }

    func selectedColor(color: UIColor) {
        preferences.set(key: .accentColor, value: color.hexValue)

        publisher.send(.settingsColor(Color(color)))
    }

    private func cachableColorIndex() -> Int? {
        accentColor.firstIndex(where: { $0.hexValue == self.preferences.accentColor.hexValue })
    }
}
