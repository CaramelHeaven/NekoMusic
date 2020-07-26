//
//  UserDefaultsRequests.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 23/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

final class UserPreferences {
    enum DefaultSettings: String {
        case accentColor
        case serverFolderId
        case databasePath
        case isAppFirstLaunched
    }

    var accentColor: UIColor {
        guard let hexStr = gettableKey(key: .accentColor) as? String else {
            return UIColor.white
        }

        return UIColor(hex: hexStr)
    }

    var serverFolderId: String? {
        gettableKey(key: .serverFolderId) as? String
    }

    var databasePath: URL? {
        gettableKey(key: .databasePath) as? URL
    }

    var isAppFirstLaunched: Bool {
        gettableKey(key: .isAppFirstLaunched) as? Bool ?? true
    }

    func set(key: DefaultSettings, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    private func gettableKey(key: DefaultSettings) -> Any? {
        return UserDefaults.standard.object(forKey: key.rawValue)
    }
}
