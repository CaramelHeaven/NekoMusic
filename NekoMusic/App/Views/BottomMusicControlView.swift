//
//  BottomMusicControlView.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 14/04/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

fileprivate enum BottomConstants {
    static let radius: CGFloat = 20
    static let indicatorHeight: CGFloat = 6
    static let indicatorWidth: CGFloat = 60
    static let snapRatio: CGFloat = 0.25
    static let minHeightRatio: CGFloat = 0.3
}

struct BottomMusicControlView: View {
    @ObservedObject var viewModel: TrackListViewModel = try! diContainer.resolve()

    private let viewHeight: CGFloat
    private let paddingWidth: CGFloat = 22

    init(height: CGFloat) {
        self.viewHeight = height
    }

    var body: some View {
        MusicCurrentPlayer()
            .frame(width: UIScreen.main.bounds.width - paddingWidth, height: viewHeight)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(self.viewModel.accentColor, lineWidth: 4))
    }
}

fileprivate struct MusicCurrentPlayer: View {
    @ObservedObject var viewModel: TrackListViewModel = try! diContainer.resolve()

    var body: some View {
        VStack {
            Text(self.viewModel.playingMusicName)
                .foregroundColor(Color(UIColor.label))
                .font(Font.custom("Menlo-Regular", size: 14))
                .lineLimit(1)
            ZStack {
                HStack(spacing: 40) {
                    Button(action: {
                        self.viewModel.playNext(direction: .previous)
                    }) {
                        Image(systemName: "backward")
                            .resizable()
                            .frame(width: 30, height: 24)
                            .foregroundColor(self.viewModel.accentColor)
                    }
                    .padding(.all, 4)
                    .background(Color(UIColor.systemBackground))

                    Button(action: {
                        self.viewModel.play(self.viewModel.currentTrack)
                    }) {
                        Image(systemName: self.viewModel.isTrackPlaylable ? "stop" : "play")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(self.viewModel.accentColor)
                    }
                    .padding(.all, 4)
                    .background(Color(UIColor.systemBackground))

                    Button(action: {
                        self.viewModel.playNext(direction: .next)
                    }) {
                        Image(systemName: "forward")
                            .resizable()
                            .frame(width: 30, height: 24)
                            .foregroundColor(self.viewModel.accentColor)
                    }
                    .padding(.all, 4)
                    .background(Color(UIColor.systemBackground))
                }

                if !viewModel.selectedTracks.isEmpty {
                    HStack {
                        Spacer()

                        Button(action: {
                            self.viewModel.dialog()
                        }) {
                            Image(systemName: "triangle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(self.viewModel.accentColor)
                        }
                        .padding(.all, 6)
                        .background(Color(UIColor.systemBackground))
                    }
                    .padding([.leading, .trailing], 8)
                }
            }.padding(.top, 14)
        }
    }
}
