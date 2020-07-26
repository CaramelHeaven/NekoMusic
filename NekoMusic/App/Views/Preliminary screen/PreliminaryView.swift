//
//  PreliminaryView.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 26/07/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

struct PreliminaryView: View {
    @ObservedObject private var viewModel = diContainer.resolve(type: PreliminaryViewModel.self)

    var body: some View {
        Text("adasdas")
    }
}

#if DEBUG
    struct PreliminaryView_Previews: PreviewProvider {
        static var previews: some View {
            PreliminaryView()
        }
    }
#endif
