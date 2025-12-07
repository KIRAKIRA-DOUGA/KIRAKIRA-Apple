//
//  MeView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct MeView: View {
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        UserView()
                    } label: {
                        LabeledContent {
                            Text("个人主页")
                        } label: {
                            HStack(spacing: 12) {
                                Image("SamplePortrait")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("艾了个拉")
                                        .font(.title3)

                                    Text("@Aira")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        MyNotificationsView()
                    } label: {
                        Label("通知", systemImage: "bell")
                            .badge(3)
                    }

                    NavigationLink {
                        MyMessagesView()
                    } label: {
                        Label("消息", systemImage: "message")
                            .badge(10)
                    }
                }

                Section {
                    NavigationLink {
                        MyCollectionsView()
                    } label: {
                        Label("收藏", systemImage: "star")
                    }

                    NavigationLink {
                        MyHistoryView()
                    } label: {
                        Label(
                            "历史",
                            systemImage:
                                "clock.arrow.trianglehead.counterclockwise.rotate.90"
                        )
                    }
                }

            }
            .contentMargins(.top, 16)
            .navigationTitle("个人")
            #if !os(macOS)
                //				.navigationBarTitleDisplayMode(.inline)
                .toolbarTitleDisplayMode(.inlineLarge)
            #endif
            .toolbar {
                ToolbarItem {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MeView()
}
