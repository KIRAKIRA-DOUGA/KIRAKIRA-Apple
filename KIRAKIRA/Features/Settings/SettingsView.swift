import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State var path = NavigationPath()
    @State private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if authManager.isAuthenticated {
                    Section {
                        NavigationLink {
                            SettingsProfileView()
                        } label: {
                            Label(.settingsProfile, systemImage: "person.crop.circle")
                        }
                        
                        NavigationLink {
                            
                        } label: {
                            Label(.settingsPrivacy, systemImage: "hand.raised")
                        }
                        
                        NavigationLink(value: SettingsPath.security) {
                            Label(.security, systemImage: "lock")
                        }
                        
                        NavigationLink {
                            
                        } label: {
                            Label(.settingsBlockAndHide, systemImage: "nosign")
                        }
                        
                        NavigationLink {
                            
                        } label: {
                            Label(.invitationCode, systemImage: "gift")
                        }
                    } header: {
                        Text(.settingsMe)
                    }
                }

                Section {
                    NavigationLink {
                        SettingsAppearanceView()
                    } label: {
                        Label(.settingsAppearance, systemImage: "paintbrush")
                    }

                    NavigationLink {
                        SettingsPlayerView()
                    } label: {
                        Label(.settingsPlaying, systemImage: "play")
                    }

                    NavigationLink {
                        SettingsDanmakuView()
                    } label: {
                        Label(.settingsDanmaku, systemImage: "list.bullet.indent")
                    }

                    NavigationLink {
                        SettingsAboutView()
                    } label: {
                        Label(.settingsAbout, systemImage: "info.circle")
                    }
                } header: {
                    Text(.settingsGeneral)
                }
                
                Section {
                    NavigationLink {
                        SettingsSwitchAccountView()
                    } label: {
                        Text(.switchAccount)
                    }

                    if authManager.isAuthenticated {
                        Button(.logOut, role: .destructive, action: {})
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(.settings)
            .navigationDestination(for: SettingsPath.self) { route in
                switch route {
                case .security:
                    SettingsSecurityView(path: $path)
                case .changeEmailPasswordVerification:
                    ChangeEmailPasswordVerification(path: $path)
                case .changeEmailNewAddress:
                    ChangeEmailViewNewAddress(path: $path)
                case .changeEmailNewAddressVerification:
                    ChangeEmailViewNewAddressVerification(path: $path)
                case .changeEmailSuccess:
                    ChangeEmailViewSuccess(path: $path)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close, systemImage: "xmark", role: .close, action: { dismiss() })
                }
            }
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

enum SettingsPath: Hashable {
    case security
    case changeEmailPasswordVerification
    case changeEmailNewAddress
    case changeEmailNewAddressVerification
    case changeEmailSuccess
}

#Preview(traits: .commonPreviewTrait) {
    SettingsView()
}
