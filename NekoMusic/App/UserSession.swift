//
//  UserSession.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 07/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import GoogleSignIn

final class UserSession {
    var apiKey = "AIzaSyB_C9cPKhYEoy6pgq84DbeK79jrym-ny3w" // google
    var accessToken = ""

    var user: GIDGoogleUser?

    init(_ user: GIDGoogleUser? = nil) {
        self.user = user
    }
}
