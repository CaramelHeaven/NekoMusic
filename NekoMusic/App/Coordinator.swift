//
//  Coordinator.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 30/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import SwiftUI

class Coordinator {
    let window: UIWindow

    private(set) var subscribers: Set<AnyCancellable> = []

    init(_ window: UIWindow) {
        self.window = window

        subscribed()
    }

    func preliminary() {
        window.overrideUserInterfaceStyle = .dark
        push(UIHostingController(rootView: PreliminaryView()))
    }

    func files() {
        push(UIHostingController(rootView: FilesView()))
    }

    func main() {
        push(UIHostingController(rootView: MainView()))
    }

    private func push<T>(_ vc: UIHostingController<T>) {
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
}

// MARK: - Subscribers

extension Coordinator: ObservableCommands {
    func subscribed() {
        reporter
            .compactMap { $0.extractable(by: CoordinatorView.self) }
            .sink { value in
                switch value {
                case .preliminary:
                    self.preliminary()
                case .files:
                    self.files()
                case .main:
                    self.main()
                }
            }
            .store(in: &subscribers)
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.windows.first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
