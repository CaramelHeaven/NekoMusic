//
//  SquareAlert.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 02/08/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import SwiftUI

/// The square toast which looked like apple toast
struct SquareAlert: View {
    @ObservedObject private var viewModel = diContainer.resolve(type: SquareAlertViewModel.self)

    @State private var animationControl = false

    var body: some View {
        VStack {
            Text(self.viewModel.title)
                .font(Font.custom("Menlo-Regular", size: 14))
                .lineLimit(1)

            Image("cat_0")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 210, height: 210)
                .cornerRadius(16)
        }
        .frame(width: 210, height: 230)
        .modifier(
            Transition(y: animationControl ? -6 : -20)
                .ignoredByLayout()
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
        )
        .onAppear(perform: {
            self.animationControl.toggle()
        })
    }
}

fileprivate struct Transition: GeometryEffect {
    var y: CGFloat = 0

    var animatableData: CGFloat {
        get { y }
        set { y = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: y))
    }
}

#if DEBUG
    struct SquareAlert_Previews: PreviewProvider {
        static var previews: some View {
            SquareAlert()
        }
    }
#endif
