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
    }

    var accentColor: UIColor {
        guard let hexStr = self.gettable(key: .accentColor) as? String else {
            return UIColor.white
        }

        return UIColor(hex: hexStr)
    }

    var serverFolderId: String? {
        gettable(key: .serverFolderId) as? String
    }

    func gettable(key: DefaultSettings) -> Any? {
        return UserDefaults.standard.object(forKey: key.rawValue)
    }

    func set(key: DefaultSettings, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
