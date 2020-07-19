//
//  MainView.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 10/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel = diContainer.resolve(type: MainViewModel.self)

    @State private var willOpenImportFolder = false
    @State var currentPageIndex = 1

    let subviews = [
        UIHostingController(rootView: SettingsScreen()),
        UIHostingController(rootView: TrackListScreen()),
        UIHostingController(rootView: PlaylistsScreen()),
    ]

    var body: some View {
        ZStack {
            if viewModel.filesImportNeeded {
                ZStack {
                    FilesView()
                }
            } else {
                PageViewController(currentPageIndex: $currentPageIndex, viewControllers: subviews)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}
