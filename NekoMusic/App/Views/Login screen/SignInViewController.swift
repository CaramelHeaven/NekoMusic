//
//  TestViewController.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import GoogleSignIn
import SwiftUI

final class SignInViewController: UIViewController, GIDSignInUIDelegate {
    @IBOutlet private weak var googleDriveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        makeViews()
    }

    private func makeViews() {
        googleDriveButton.backgroundColor = .clear
        googleDriveButton.layer.cornerRadius = 5
        googleDriveButton.layer.borderWidth = 1
        googleDriveButton.layer.borderColor = UIColor.black.cgColor
        googleDriveButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        googleDriveButton.setTitleColor(.black, for: .normal)

        googleDriveButton.addTarget(self, action: #selector(googleDrivePressed(_:)), for: .touchUpInside)
    }

    @objc private func googleDrivePressed(_ button: UIButton) {
        let scopes = ["https://www.googleapis.com/auth/drive"]

        GIDSignIn.sharedInstance()?.scopes = scopes
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self

        GIDSignIn.sharedInstance()?.signIn()
    }
}

extension SignInViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        guard let user = user, error == nil else {
            print("SignInViewController err: \(error!)")
            return
        }

        guard let window = UIApplication.shared.windows.first else {
            return
        }

        UserSession.shared.accessToken = user.authentication?.accessToken ?? ""

        window.overrideUserInterfaceStyle = .dark

        window.rootViewController = UIHostingController(rootView: MainView())
    }
}
