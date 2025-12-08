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
                        HStack(spacing: 12) {
                            Image("SamplePortrait")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 5) {
                                Text(verbatim: "艾了个拉")
                                    .font(.title3)

                                Text(verbatim: "@Aira")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        MyNotificationsView()
                    } label: {
                        Label("NOTIFICATION", systemImage: "bell")
                            .badge(3)
                    }

                    NavigationLink {
                        MyMessagesView()
                    } label: {
                        Label("MESSAGES", systemImage: "message")
                            .badge(10)
                    }
                }

                Section {
                    NavigationLink {
                        MyCollectionsView()
                    } label: {
                        Label("FAVORITE", systemImage: "star")
                    }

                    NavigationLink {
                        MyHistoryView()
                    } label: {
                        Label(
                            "HISTORY",
                            systemImage:
                                "clock.arrow.trianglehead.counterclockwise.rotate.90"
                        )
                    }
                }

            }
            .contentMargins(.top, 16)
            .navigationTitle("ME")
            .toolbarTitleDisplayMode(.inlineLarge)
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
