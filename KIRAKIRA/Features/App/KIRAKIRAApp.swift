//
//  KIRAKIRAApp.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

@main
struct KIRAKIRAApp: App {
    @State private var appDependencies = AppDependencies(sessionStore: .shared)
    @State private var appRouter = AppRouter()
    @State private var appUIState = AppUIState()
    @State private var playbackState = PlaybackState()
    @State private var homeBrowseState = HomeBrowseState()
    @State private var isSplashShowing = true
    @State private var isSplashVisible = true
    @State private var isSplashHitAllowed = true
    @AppSetting(\.globalColorScheme) private var globalColorScheme
    private var appearanceManager = AppearanceManager()

    var body: some Scene {
        WindowGroup {
            MainView(dependencies: appDependencies)
                .environment(appRouter)
                .environment(appUIState)
                .environment(playbackState)
                .environment(homeBrowseState)
                .environment(appDependencies.authManager)
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        isSplashShowing = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isSplashHitAllowed = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSplashVisible = false
                        }
                    }
                })
                .overlay {
                    if isSplashVisible {
                        LaunchScreenView(isShowing: isSplashShowing, isHitAllowed: isSplashHitAllowed)
                    }
                }
                .task {
                    appearanceManager.updateWindowStyle()
                }
                .onChange(of: globalColorScheme) {
                    appearanceManager.updateWindowStyle()
                }
        }
    }
}
