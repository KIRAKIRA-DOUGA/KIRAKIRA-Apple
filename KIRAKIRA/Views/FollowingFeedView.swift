//
//  FollowingFeedView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct FollowingFeedView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(1...20, id: \.self) { _ in
                        // VideoListItemView()
                        EmptyView()
                    }
                }.padding()
            }
            .navigationTitle("MAINTAB_FOLLOWING")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ProfileToolbarItem()
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
