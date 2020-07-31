//
//  MainControlViewModel.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 08/06/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Combine

class MainViewModel: ObservableObject {
    var subscribers: Set<AnyCancellable> = []

    init() {
        subscribed()
    }
}

extension MainViewModel: ObservableCommands {
    func subscribed() {
//        reporter
//            .filter { $0 == .userChoosedFolder }
//            .sink { [weak self] _ in
//                self?.filesImportNeeded = false
//            }
//            .store(in: &subscribers)
    }
}
