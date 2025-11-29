//
//  HomeView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct HomeView: View {
    @Binding var tabSelection: MainTab
    @State private var showingView: viewTab = .latest

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 140), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...20, id: \.self) { _ in
                        VideoItemView()
                    }
                }.padding()
            }
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 40)
                        .foregroundStyle(.accent)
                }.sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .principal) {
                    Picker("页面", selection: $showingView) {
                        Text("最新").tag(viewTab.latest)
                        Text("最热").tag(viewTab.hot)
                    }.pickerStyle(.segmented)
                }
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

private enum viewTab: Hashable {
    case latest
    case hot
}

#Preview {
    MainView()
}
