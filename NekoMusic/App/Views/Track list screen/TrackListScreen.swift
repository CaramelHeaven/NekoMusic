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
    @ObservedObject var viewModel = diContainer.resolve(type: TrackListViewModel.self)

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
            if self.viewModel.tracks.count > 0 {
                ZStack {
                    NavigationView {
                        VStack {
                            List {
                                ForEach(0..<viewModel.tracks.count, id: \.self) { index in
                                    TrackRow(track: self.viewModel.tracks[index])
                                }
                            }
                            .padding(.top, 120)
                            .offset(y: -120)
                        }
                        .animation(.default)
                        .navigationBarTitle("Music", displayMode: .inline)
                        .navigationBarItems(trailing:
                            HStack(spacing: 20) {
                                Button(action: {
                                    self.viewModel.load(isNeedSyncFromRemote: true)
                                }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .imageScale(.large)
                                        .foregroundColor(self.viewModel.accentColor)
                                }

                                Button(action: {
//                                    self.viewModel.uploadLocalPlaylistsToServer()
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .imageScale(.large)
                                        .foregroundColor(self.viewModel.accentColor)
                                }
                            }
                        )
                    }

                    BottomMusicControlView(height: 100)
                }
            } else {
                DownloadingAlert(viewModel: self.viewModel)
            }
        }
    }
}

// MARK: - Track Row in table view

struct TrackRow: View {
    @ObservedObject var viewModel = diContainer.resolve(type: TrackListViewModel.self)

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

// MARK: - Alerts

struct DownloadingAlert: View {
    @ObservedObject var viewModel: TrackListViewModel = try! diContainer.resolve()
    @State var pepeOffset: CGFloat = -6

    var body: some View {
        return ZStack {
            DownloadingAlertForm()

            // It's interesting if we put image inside DownloadAlertForm it will be freezing sometimes while text is updating.
            Image("pepe-test")
                .resizable()
                .frame(width: 100, height: 100)
                .offset(y: pepeOffset)
                .onAppear(perform: {
                    self.pepeOffset = -20
                })
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
        }
    }
}

struct DownloadingAlertForm: View {
    @ObservedObject var viewModel: TrackListViewModel = try! diContainer.resolve()

    var body: some View {
        return ZStack {
            Text("Downloaded items \(viewModel.downloadedCount) \\ \(viewModel.tracksCount)")
                .font(Font.custom("Menlo-Regular", size: 14))
                .offset(y: 60)
        }
        .frame(width: 250, height: 250)
        .background(Color(.displayP3, white: 0.9, opacity: 0.2))
        .cornerRadius(16)
    }
}
