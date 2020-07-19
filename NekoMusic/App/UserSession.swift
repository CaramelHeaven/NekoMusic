//
//  UserSession.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 07/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

final class UserSession {
    static let shared = UserSession()

    var apiKey = "AIzaSyB_C9cPKhYEoy6pgq84DbeK79jrym-ny3w" // google
    var accessToken = ""

    private init() {}
}
