//
//  FeedView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct FeedView: View {
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
            .navigationTitle("关注")
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
