//
//  TestViewController.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import GoogleSignIn
import SwiftUI

final class SignInViewController: UIViewController {
    @IBOutlet private weak var googleDriveButton: UIButton!

    private let preferences = diContainer.resolve(type: UserPreferences.self)
    private let scopes = ["https://www.googleapis.com/auth/drive"]
    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance()?.scopes = scopes
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self

        makeViews()
        guard !preferences.isAppFirstLaunched else {
            return
        }

        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
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
        GIDSignIn.sharedInstance()?.signIn()
    }
}

extension SignInViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        guard let user = user, error == nil else {
            print("ERR: \(error!)")
            return
        }
        diContainer.register(.singleton) { UserSession(user) }

        guard preferences.isAppFirstLaunched else {
            reporter.send(.coordinator(.main))
            return
        }

        diContainer.resolve(type: DatabaseSynchronization.self)
            .sync(direction: .fromRemote)

        // Needed a delay 'cause GIDSignIn has a delay for closing own signIn controller I presume.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
            reporter.send(.coordinator(.files))
        }
    }
}
