//
//  ChooseImportFoldersView.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 25/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

struct FilesView: View {
    @ObservedObject var viewModel = diContainer.resolve(type: FilesViewModel.self)

    @State var highlitedRow: Int?

    init() {
        if let font = UIFont(name: "Menlo-Bold", size: 28) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: font]
        }

        UITableView.appearance().separatorStyle = .none
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Choose ur preferred folder where u'll import music files")
                    .font(Font.custom("Menlo-Regular", size: 14))
                    .padding([.leading, .trailing], 8)
                    .padding(.top, 12)

                List {
                    if viewModel.files.count > 0 {
                        ForEach(0..<self.viewModel.files.count, id: \.self) { index in
                            FileView(file: self.viewModel.files[index], rowSelected: self.highlitedRow == index)
                                .onTapGesture {
                                    self.highlitedRow = index
                                    self.viewModel.select(rowIndex: index)
                                }
                        }
                    }
                }

                if highlitedRow != nil {
                    Button(action: {
                        self.viewModel.save()
                    }) {
                        ZStack {
                            Rectangle()
                                .opacity(0)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 3))
                                .padding(.all, 4)

                            Text("Import: \(self.viewModel.selectedFile?.name ?? "")")
                                .font(Font.custom("Menlo-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(width: UIScreen.main.bounds.width, height: 64)
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }.navigationBarTitle("Choose folder", displayMode: .inline)
        }
    }
}

struct FileView: View {
    let file: GoogleFile
    var rowSelected: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if rowSelected {
                Rectangle()
                    .opacity(0)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.white, lineWidth: 3))
            }

            HStack {
                Image(systemName: "folder")
                    .resizable()
                    .frame(width: 30, height: 24)
                    .foregroundColor(Color.white)

                Text(file.name)
                    .font(Font.custom("Menlo-Regular", size: 14))

                Spacer()
            }
            .padding([.top, .bottom], 12)
            .padding([.leading, .trailing], 8)
        }
        .background(Color(UIColor.systemBackground))
    }
}
