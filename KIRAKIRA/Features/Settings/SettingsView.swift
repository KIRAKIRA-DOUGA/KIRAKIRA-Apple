import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared
    @State private var operationInProgress = false

    var body: some View {
        @Bindable var globalStateManager = globalStateManager

        NavigationStack(path: $globalStateManager.settingsPath) {
            List {
                if authManager.isAuthenticated {
                    Section {
                        NavigationLink(value: SettingsPath.profile) {
                            Label(.settingsProfile, systemImage: "person.crop.circle")
                        }
                        
                        NavigationLink(value: SettingsPath.privacy) {
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
                        Button(.logOut, role: .destructive) {
                            Task { await authManager.logout() }
                        }
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(.settings)
            .navigationDestination(for: SettingsPath.self) { route in
                switch route {
                case .profile:
                    SettingsProfileView()
                case .privacy:
                    SettingsPrivacyView()
                case .security:
                    SettingsSecurityView(path: $globalStateManager.settingsPath)
                case .changeEmailPasswordVerification:
                    ChangeEmailPasswordVerification(path: $globalStateManager.settingsPath)
                case .changeEmailNewAddress:
                    ChangeEmailViewNewAddress(path: $globalStateManager.settingsPath)
                case .changeEmailNewAddressVerification:
                    ChangeEmailViewNewAddressVerification(path: $globalStateManager.settingsPath)
                case .changeEmailSuccess:
                    ChangeEmailViewSuccess(path: $globalStateManager.settingsPath)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close, systemImage: "xmark", role: .close) {
                        guard !operationInProgress else { return }
                        dismiss()
                    }
                    .disabled(operationInProgress)
                }
            }
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onPreferenceChange(SettingsOperationInProgressPreferenceKey.self) { operationInProgress = $0 }
        .interactiveDismissDisabled(operationInProgress)
    }
}

enum SettingsPath: Hashable {
    case profile
    case privacy
    case security
    case changeEmailPasswordVerification
    case changeEmailNewAddress
    case changeEmailNewAddressVerification
    case changeEmailSuccess
}

// MARK: - Child operation dismissal protection

struct SettingsOperationInProgressPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

#Preview(traits: .commonPreviewTrait) {
    SettingsView()
}
