//
//  TrackListScreen.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 12/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine
import SwiftUI

extension Color {
    static let musicBottomRed = Color(red: 230 / 255, green: 90 / 255, blue: 107 / 255)
}

struct TrackListScreen: View {
    @ObservedObject private var viewModel = diContainer.resolve(type: TrackListViewModel.self)

    init() {
        UITableView.appearance().separatorStyle = .none
    }

    var body: some View {
        ZStack {
            if self.viewModel.isError {
                Text("Error")
            } else {
                musicBody()
            }
        }
    }

    func musicBody() -> some View {
        ZStack {
            ZStack {
                NavigationView {
                    VStack {
                        List {
                            ForEach(0..<viewModel.tracks.count, id: \.self) { index in
                                TrackRow(track: self.viewModel.tracks[index])
                            }
                        }
                        Spacer()

                        BottomMusicControlView(height: 100)
                    }
                    .animation(.default)
                    .navigationBarTitle("Music", displayMode: .inline)
                    .navigationBarItems(trailing:
                        HStack(spacing: 60) {
                            Button(action: {
                                self.viewModel.load(isSyncNeeded: true)
                            }) {
                                Image(systemName: "square.and.arrow.down")
                                    .imageScale(.large)
                                    .foregroundColor(self.viewModel.accentColor)
                            }
                            Button(action: {
                                self.viewModel.locallyPush()
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .imageScale(.large)
                                    .foregroundColor(self.viewModel.accentColor)
                            }
                        }
                    )
                }
            }

            if viewModel.isLoadingTracks {
                SquareAlert()
            }
        }
    }
}

// MARK: - Track Row

fileprivate struct TrackRow: View {
    @ObservedObject private var viewModel = diContainer.resolve(type: TrackListViewModel.self)

    let track: Track

    private var rowPlaying: Bool {
        viewModel.currentTrack == track
    }

    var body: some View {
        ZStack(alignment: .top) {
            if track.isTrackSelected {
                Rectangle()
                    .opacity(0)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(self.viewModel.accentColor, lineWidth: 3))
            }

            HStack {
                VStack(alignment: .leading) {
                    Text(track.uiName)
                        .font(Font.custom("Menlo-Regular", size: 14))
                        .lineLimit(2)

                    Text(track.uiPlaylists)
                        .font(Font.custom("Menlo-Regular", size: 12))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }

                Spacer()

                Rectangle()
                    .foregroundColor(self.rowPlaying ? self.viewModel.accentColor : Color(UIColor.systemBackground))
                    .frame(width: 3)
            }
            .opacity(0.9)
            .background(Color(UIColor.systemBackground)) // for tappable area
            .padding(.all, 6)
            .onTapGesture(count: 2, perform: {
                self.track.isTrackSelected.toggle()

                self.viewModel.doublePressed(on: self.track)
            })
            .onTapGesture {
                self.viewModel.play(self.track)
            }
        }
    }
}
