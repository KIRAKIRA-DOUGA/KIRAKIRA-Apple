//
//  LaunchScreenView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/21.
//

import SwiftUI

struct LaunchScreenView: View {
    var isShowing = true
    var isHitAllowed = true

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.launchScreenBackground)

            ZStack {
                Image("Logo")
                    .resizable()
                    .foregroundStyle(.black)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128)
                    .blendMode(.destinationOut)

                // 白色层
                Image("Logo")
                    .resizable()
                    .foregroundStyle(.launchScreenForeground)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128)
                    .opacity(isShowing ? 1.0 : 0.0)
            }
            .scaleEffect(isShowing ? 1.0 : 26.0)
            .offset(x: isShowing ? 0.0 : 650, y: isShowing ? 0.0 : -400)
            .animation(
                .timingCurve(
                    .bezier(
                        startControlPoint: .init(x: 1.0, y: -0.2),
                        endControlPoint: .init(x: 0.3, y: 1.0)
                    ),
                    duration: 0.5
                ),
                value: isShowing
            )

            // debug用按钮 调试完记得注释掉
            //			VStack {
            //				Spacer()
            //				Button(action: {
            //					var transaction = Transaction()
            //					transaction.disablesAnimations = true
            //					withTransaction(transaction) {
            //						isShowing = true
            //					}
            //					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            //						isShowing = false
            //					}
            //				}) {
            //					Image(systemName: "play.fill")
            //				}
            //				.controlSize(.large)
            //				.buttonBorderShape(.circle)
            //				.buttonStyle(.glass)
            //				.padding()
            //			}
        }
        .allowsHitTesting(isHitAllowed)
        .ignoresSafeArea()
        .compositingGroup()
    }
}

#Preview {
    LaunchScreenView()
}
