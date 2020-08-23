//
//  MainView.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 10/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @State private var currentPage = 1

    let subviews = [
        UIHostingController(rootView: SettingsScreen()),
        UIHostingController(rootView: TrackListScreen()),
        UIHostingController(rootView: PlaylistsScreen()),
    ]

    var body: some View {
        PagerView(pageCount: 3, currentIndex: $currentPage) {
            SettingsScreen(); TrackListScreen(); PlaylistsScreen()
        }
    }
}

fileprivate struct PagerView<Content: View>: View {
    @GestureState private var translation: CGFloat = 0
    @Binding var currentIndex: Int

    let pageCount: Int
    let content: Content

    init(pageCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.pageCount = pageCount
        self._currentIndex = currentIndex
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                self.content.frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .offset(x: -1 * CGFloat(self.currentIndex) * geometry.size.width)
            .offset(x: self.translation)
            .animation(.interactiveSpring())
            .gesture(
                // 25 is a value for delete action in list - playlist screen
                DragGesture(minimumDistance: 25, coordinateSpace: .global)
                    .updating(self.$translation) { value, state, _ in
                        switch self.currentIndex {
                        case 0:
                            guard value.translation.width < 0 else { return }
                        case 2:
                            guard value.translation.width > 0 else { return }
                        default:
                            break
                        }
                        state = value.translation.width
                    }.onEnded { value in
                        let offset = value.translation.width / geometry.size.width
                        let newIndex = (CGFloat(self.currentIndex) - offset).rounded()

                        self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
                    }
            )
        }
    }
}
