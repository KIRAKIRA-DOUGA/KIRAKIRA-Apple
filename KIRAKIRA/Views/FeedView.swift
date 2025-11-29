//
//  FeedView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct FeedView: View {
    @Binding var tabSelection: MainTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(1...20, id: \.self) { _ in
                        VideoItemView()
                    }
                }.padding()
            }
            .navigationTitle("关注")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { tabSelection = .me }) {
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
    MainView(tabSelection: .feed)
}
