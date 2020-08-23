//
//  PlaylistsScreen.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 03/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

struct PlaylistsScreen: View {
    @ObservedObject private var viewModel = diContainer.resolve(type: PlaylistsViewModel.self)

    @State var highlightedRow: Int?

    init() {
        UITableView.appearance().separatorStyle = .none
    }

    var body: some View {
        NavigationView {
            ZStack {
                if self.viewModel.playlists.isEmpty {
                    Text("Playlists contains 0")
                } else {
                    List {
                        if self.viewModel.isPlaylistEnable {
                            Button(action: {
                                self.highlightedRow = nil

                                self.viewModel.reset()
                            }) {
                                ZStack {
                                    Rectangle()
                                        .opacity(0)
                                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(self.viewModel.accentColor, lineWidth: 3))
                                        .cornerRadius(4)

                                    HStack {
                                        Spacer()

                                        Text("Reset")
                                            .font(Font.custom("Menlo-Regular", size: 20))

                                        Spacer()
                                    }
                                }.padding(.all, 4)
                            }
                            .frame(width: UIScreen.main.bounds.width, height: 44)
                            .cornerRadius(6)
                            .padding(.leading, -20)
                        }

                        ForEach(0..<viewModel.playlists.count, id: \.self) { index in
                            PlaylistRow(playlist: self.viewModel.playlists[index], isRowSelected: self.highlightedRow == index)
                                .onTapGesture {
                                    self.highlightedRow = index

                                    self.viewModel.select(playlist: self.viewModel.playlists[index])
                                }
                        }
                        .onDelete {
                            self.viewModel.remove(rows: $0)
                        }
                    }
                    .id(UUID())
                }
            }.navigationBarTitle("Albums", displayMode: .inline)
        }
    }
}

struct PlaylistRow: View {
    @ObservedObject var viewModel = diContainer.resolve(type: TrackListViewModel.self)

    let playlist: Playlist
    var isRowSelected: Bool

    var body: some View {
        ZStack {
            if isRowSelected {
                Rectangle()
                    .opacity(0)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(self.viewModel.accentColor, lineWidth: 3))
                    .cornerRadius(4)
            }

            HStack {
                Spacer()

                Text(playlist.name)
                    .padding(.all, 10)
                    .font(Font.custom("Menlo-Regular", size: 14))

                Spacer()
            }
        }.background(Color(UIColor.systemBackground))
    }
}
