//
//  SettingsScreen.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 23/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

struct SettingsScreen: View {
    init() {
        if let font = UIFont(name: "Menlo-Bold", size: 28) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: font]
        }

        UITableView.appearance().separatorStyle = .none
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(0..<1, id: \.self) { _ in
                        Section(header: Text("UI preferences").font(Font.custom("Menlo-Regular", size: 16))) {
                            Text("Accent Colour")
                                .font(Font.custom("Menlo-Regular", size: 14))

                            AccentColorPicker()
                        }
                    }
                }.navigationBarTitle("Settings")
            }
        }
    }
}

struct AccentColorPicker: View {
    @ObservedObject var viewModel = diContainer.resolve(type: SettingsViewModel.self)

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(0..<self.viewModel.accentColor.count) { i in
                        ZStack {
                            if self.viewModel.selectedAccentIndex == i {
                                Rectangle()
                                    .opacity(0)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2))
                            }

                            Rectangle()
                                .cornerRadius(4)
                                .frame(width: 50, height: 50)
                                .padding(.all, 4)
                                .foregroundColor(Color(self.viewModel.accentColor[i]))
                                .onTapGesture {
                                    self.viewModel.selectedAccentIndex = i
                                    self.viewModel.selectedColor(color: self.viewModel.accentColor[i])
                                }
                        }
                    }
                }.padding(.all, 4)
            }.frame(height: 70)
        }
    }
}
