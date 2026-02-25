import SwiftUI

struct MyView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            List {
                if authManager.isAuthenticated {
                    Section {
                        NavigationLink {
                            UserView()
                        } label: {
                            LabeledContent {
                                Text(.userPage)
                            } label: {
                                HStack {
                                    Image("SamplePortrait")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 55, height: 55)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(verbatim: "艾了个拉")
                                            .bold()
                                        
                                        Text(verbatim: "@Aira")
                                            .font(.caption)
                                            .fontDesign(.monospaced)
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
                            Label(.notifications, systemImage: "bell")
                                .badge(3)
                        }

                        NavigationLink {
                            MyMessagesView()
                        } label: {
                            Label(.messages, systemImage: "message")
                                .badge(10)
                        }
                    }

                    Section {
                        NavigationLink {
                            MyCollectionsView()
                        } label: {
                            Label(.userCollections, systemImage: "star")
                        }

                        NavigationLink {
                            MyHistoryView()
                        } label: {
                            Label(.userHistory, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                    }
                } else {
                    Button(action: { globalStateManager.isShowingLogin = true }) {  // TODO: 打开登录fullscreenCover
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 55, height: 55)
                            Text(.logIn)
                                .bold()
                        }
                    }
                }

            }
            #if os(iOS)
                .contentMargins(.top, 16)
            #endif
            .navigationTitle(.maintabMy)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem {
                    Button(.settings, systemImage: "gear") {
                        globalStateManager.isShowingSettings = true
                    }
                }
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MyView()
}
