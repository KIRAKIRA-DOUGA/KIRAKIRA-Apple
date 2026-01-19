import SwiftUI

struct SettingsSecurityView: View {
    @Binding var path: NavigationPath

    var body: some View {
        Form {
            Section {
                NavigationLink(value: SettingsPath.changeEmailPasswordVerification) {
                    Label(
                        title: {
                            VStack(alignment: .leading) {
                                Text(.emailAddress)
                                    .font(.headline)
                                Text(verbatim: "myname@example.com")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        },
                        icon: {
                            Image(systemName: "envelope")
                        }
                    )
                }
                
                NavigationLink {

                } label: {
                    Label(
                        title: {
                            VStack(alignment: .leading) {
                                Text(.password)
                                    .font(.headline)
                                Text(verbatim: "最后更改：XXX")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        },
                        icon: {
                            Image(systemName: "key")
                        }
                    )
                }
            }

            Section {
                NavigationLink {

                } label: {
                    LabeledContent {
                        Text(.on)
                    } label: {
                        Label(.emailAddress, systemImage: "envelope")
                    }
                }
                NavigationLink {

                } label: {
                    LabeledContent {
                        Text(.off)
                    } label: {
                        Label(.authenticator, systemImage: "lock.badge.clock")
                    }
                }

                NavigationLink {

                } label: {
                    LabeledContent {
                        Text(verbatim: "1")
                    } label: {
                        Label(.passkeys, systemImage: "person.badge.key")
                    }
                }
            } header: {
                Text(.twoFactorAuthentication)
            }
        }
        .navigationTitle(.security)
    }
}

struct ChangeEmailPasswordVerification: View {
    @Binding var path: NavigationPath
    @State private var currentPassword: String = ""

    var body: some View {
        WizardForm(
            systemImage: "lock",
            title: .verifyYourIdentity,
            subtitle: .enterPasswordDescription,
        ) {
            WizardSection {
                SecureField(.password, text: $currentPassword)
                    .textContentType(.password)
            }
        } footer: {
            NavigationLink(value: SettingsPath.changeEmailNewAddress) {
                Text(.actionContinue)
            }.disabled(currentPassword.isEmpty)
        }
    }
}

struct ChangeEmailViewNewAddress: View {
    @Binding var path: NavigationPath
    @State private var newEmailAddress: String = ""

    var body: some View {
        WizardForm(
            systemImage: "envelope.badge.plus",
            title: .newEmailAddress,
            subtitle: .newEmailAddressDescription,
        ) {
            WizardSection {
                TextField(.emailAddress, text: $newEmailAddress)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
        } footer: {
            NavigationLink(value: SettingsPath.changeEmailNewAddressVerification) {
                Text(.actionContinue)
            }.disabled(newEmailAddress.isEmpty)
        }
    }
}

struct ChangeEmailViewNewAddressVerification: View {
    @Binding var path: NavigationPath
    @State private var newEmailVerificationCode: String = ""

    var body: some View {
        WizardForm(
            systemImage: "envelope.open",
            title: .verifyEmailAddress,
            subtitle: .enterVerificationCodeEmailDescription,
        ) {
            WizardSection {
                TextField(.verificationCode, text: $newEmailVerificationCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
            }
        } footer: {
            NavigationLink(value: SettingsPath.changeEmailSuccess) {
                Text(.actionContinue)
            }.disabled(newEmailVerificationCode.isEmpty)
        }
    }
}

struct ChangeEmailViewSuccess: View {
    @Binding var path: NavigationPath
    var body: some View {
        WizardForm(
            systemImage: "checkmark.circle",
            iconStyle: AnyShapeStyle(.green.gradient),
            title: .changeEmailAddressSuccessTitle,
            subtitle: .changeSettingsAccountSuccessDescription,
        ) {
            EmptyView()
        } footer: {
            Button(.actionDone) {
                var newPath = NavigationPath()
                newPath.append(SettingsPath.security)
                path = newPath
            }
        }
    }
}
