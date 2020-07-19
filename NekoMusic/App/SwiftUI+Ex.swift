//
//  SwiftUI+Ex.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 09/06/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

/*
 some kind of extensions which are not included by default in swiftui
 */

// MARK: - Push view by bool @State

extension View {
    /// Navigate to a new view.
    /// - Parameters:
    ///   - view: View to navigate to.
    ///   - binding: Only navigates when this condition is `true`.
    func navigate<SomeView: View>(to view: SomeView, when binding: Binding<Bool>, firstTitle: String, secondTitle: String) -> some View {
        modifier(NavigateModifier(binding: binding, destination: view, fromTitle: firstTitle, toTitle: secondTitle))
    }
}

fileprivate struct NavigateModifier<SomeView: View>: ViewModifier {
    @Binding fileprivate var binding: Bool

    fileprivate let destination: SomeView
    fileprivate let fromTitle: String
    fileprivate let toTitle: String

    fileprivate func body(content: Content) -> some View {
        NavigationView {
            ZStack {
                content
                    .navigationBarTitle(Text(fromTitle), displayMode: .inline)
                    .navigationBarHidden(false)

                NavigationLink(destination:
                    destination
                        .navigationBarTitle(Text(toTitle), displayMode: .inline)
                        .navigationBarHidden(false),
                    isActive: $binding) {
                    EmptyView()
                }
            }
        }.accentColor(.white)
    }
}

// MARK: - Push view without navigation link - not used

/*
 https://stackoverflow.com/questions/58958858/present-a-new-view-in-swiftui
 */

struct ViewControllerHolder {
    weak var value: UIViewController?
}

struct ViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        return ViewControllerHolder(value: UIApplication.shared.windows.first?.rootViewController)
    }
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { return self[ViewControllerKey.self].value }
        set { self[ViewControllerKey.self].value = newValue }
    }
}

extension UIViewController {
    func present<Content: View>(style: UIModalPresentationStyle = .automatic, @ViewBuilder builder: () -> Content) {
        let toPresent = UIHostingController(rootView: AnyView(EmptyView()))
        toPresent.modalPresentationStyle = style
        toPresent.rootView = AnyView(
            builder()
                .environment(\.viewController, toPresent)
        )
        present(toPresent, animated: true, completion: nil)
    }
}

// MARK: - Helping tool

extension URLRequest {
    /// Returns a cURL command for a request
    /// - return A String object that contains cURL command or "" if an URL is not properly initalized.
    public var curl: String {
        guard let url = url, let httpMethod = httpMethod, url.absoluteString.utf8.count > 0 else {
            return ""
        }

        var curlCommand = "curl \\\n"

        // URL
        curlCommand = curlCommand.appendingFormat(" '%@' \\\n", url.absoluteString)

        // Method if different from GET
        if "GET" != httpMethod {
            curlCommand = curlCommand.appendingFormat(" -X %@ \\\n", httpMethod)
        }

        // Headers
        let allHeadersFields = allHTTPHeaderFields!
        let allHeadersKeys = Array(allHeadersFields.keys)
        let sortedHeadersKeys = allHeadersKeys.sorted(by: <)
        for key in sortedHeadersKeys {
            curlCommand = curlCommand.appendingFormat(" -H '%@: %@' \\\n", key, value(forHTTPHeaderField: key)!)
        }

        // HTTP body
        if let httpBody = httpBody, httpBody.count > 0 {
            let httpBodyString = String(data: httpBody, encoding: String.Encoding.utf8)!
            /// Escapes all single quotes for shell from a given string.
            let escapedHttpBody = httpBodyString.replacingOccurrences(of: "'", with: "'\\''")
            curlCommand = curlCommand.appendingFormat(" --data '%@' \\\n", escapedHttpBody)
        }

        print(curlCommand)
        return curlCommand
    }
}
