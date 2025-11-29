//
//  KIRAKIRAApp.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

@main
struct KIRAKIRAApp: App {
    @State private var isSplashShowing = true
    @State private var isSplashVisible = true
    @State private var isSplashHitAllowed = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            isSplashShowing = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isSplashHitAllowed = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isSplashVisible = false
                            }
                        }
                    })
                if isSplashVisible {
                    LaunchScreenView(isShowing: isSplashShowing, isHitAllowed: isSplashHitAllowed)
                }
            }
        }
    }
}
