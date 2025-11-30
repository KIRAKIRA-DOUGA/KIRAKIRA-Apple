//
//  FeedView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var globalStateManager: GlobalStateManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(1...20, id: \.self) { _ in
                        // VideoItemView()
                        EmptyView()
                    }
                }.padding()
            }
            .navigationTitle("关注")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { globalStateManager.mainTabSelection = .me }) {
                        Image("SamplePortrait")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }.buttonStyle(.plain)
                }.sharedBackgroundVisibility(.hidden)
            }
        }
    }
}

#Preview {
    MainView()
}
