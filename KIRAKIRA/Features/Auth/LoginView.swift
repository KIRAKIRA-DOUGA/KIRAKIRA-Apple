import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var emailAddress = ""
    @State private var password = ""
    @State private var path: NavigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WizardForm(image: "Logo", title: .logIn, subtitle: .logInDescription) {
                WizardSection {
                    TextField(.emailAddress, text: $emailAddress)
                        .textContentType(.emailAddress)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField(.password, text: $password)
                        .textContentType(.password)
                }

                Button(.createAccount, systemImage: "plus.circle") {
                    path.append(LoginPath.registerName)
                }.buttonStyle(.borderless)
            } footer: {
                Button {
                    path.append(LoginPath.loginEmailVerification)
                } label: {
                    Text(verbatim: "LINK START")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close, systemImage: "xmark", role: .close, action: { dismiss() })
                }
            }
            .navigationDestination(for: LoginPath.self) { route in
                switch route {
                case .loginEmailVerification:
                    LoginEmailVerificationView(path: $path, dismissSheet: dismiss)
                case .loginAuthenticatorVerification:
                    LoginAuthenticatorVerificationView(path: $path, dismissSheet: dismiss)
                case .registerName:
                    RegisterNameView(path: $path)
                case .registerCredentials:
                    RegisterCredentialsView(path: $path)
                case .registerVerifyInvitationCode:
                    RegisterVerifyInvitationCodeView(path: $path)
                case .registerVerifyEmail:
                    RegisterVerifyEmailView(path: $path)
                case .registerSuccess:
                    RegisterSuccessView(dismissSheet: dismiss)
                }
            }
        }
    }
}

struct LoginEmailVerificationView: View {
    @Binding var path: NavigationPath
    let dismissSheet: DismissAction
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(
            systemImage: "envelope.badge", title: .verifyIdentity, subtitle: .enterVerificationCodeEmailDescription
        ) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .keyboardType(.numberPad)
            }
        } footer: {
            Button {
                dismissSheet()
            } label: {
                Text(verbatim: "LINK START")
            }
        }
    }
}

struct LoginAuthenticatorVerificationView: View {
    @Binding var path: NavigationPath
    let dismissSheet: DismissAction
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(
            systemImage: "lock.badge.clock", title: .verifyIdentity,
            subtitle: .enterVerificationCodeAuthenticatorDescription
        ) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .keyboardType(.numberPad)
            }
        } footer: {
            Button {
                dismissSheet()
            } label: {
                Text(verbatim: "LINK START")
            }
        }
    }
}

struct RegisterNameView: View {
    @Binding var path: NavigationPath
    @State private var username = ""
    @State private var name = ""

    var body: some View {
        WizardForm(
            systemImage: "person.crop.circle.badge.questionmark", title: .whoAreYou, subtitle: .setUpUsernameNickname
        ) {
            WizardSection {
                LabeledContent {
                    TextField(
                        .settingsProfileUsername,
                        text: $username
                    )
                } label: {
                    Text(verbatim: "@")
                }
                .fontDesign(.monospaced)

                TextField(
                    .settingsProfileNickname,
                    text: $name
                )
            }
        } footer: {
            Button {
                path.append(LoginPath.registerCredentials)
            } label: {
                Text(.actionContinue)
            }
        }
    }
}

struct RegisterCredentialsView: View {
    @Binding var path: NavigationPath
    @State private var emailAddress = ""
    @State private var password: String = ""

    var body: some View {

        WizardForm(
            systemImage: "person.crop.circle.badge.plus", title: .registerAccount, subtitle: .registerAccountDescription
        ) {
            WizardSection {
                TextField(.emailAddress, text: $emailAddress)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField(.password, text: $password)
                    .textContentType(.newPassword)
            }
        } footer: {
            Button {
                path.append(LoginPath.registerVerifyInvitationCode)
            } label: {
                Text(.actionContinue)
            }
        }
    }
}

struct RegisterVerifyInvitationCodeView: View {
    @Binding var path: NavigationPath
    @State private var invitationCode = ""

    var body: some View {
        WizardForm(systemImage: "gift", title: .verifyInvitationCode, subtitle: .verifyInvitationCodeDescription) {
            WizardSection {
                TextField(.invitationCode, text: $invitationCode)
            }
        } footer: {
            Button {
                path.append(LoginPath.registerVerifyEmail)
            } label: {
                Text(.actionContinue)
            }
        }
    }
}

struct RegisterVerifyEmailView: View {
    @Binding var path: NavigationPath
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(
            systemImage: "envelope.badge", title: .verifyEmailAddress, subtitle: .enterVerificationCodeEmailDescription
        ) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .keyboardType(.numberPad)
            }
        } footer: {
            Button {
                path.append(LoginPath.registerSuccess)
            } label: {
                Text(.actionContinue)
            }
        }
    }
}

struct RegisterSuccessView: View {
    let dismissSheet: DismissAction
    var body: some View {
        WizardForm(
            systemImage: "checkmark.circle", iconStyle: AnyShapeStyle(.green.gradient), title: .registerSuccess,
            subtitle: .registerSuccessDescription
        ) {
            EmptyView()
        } footer: {
            Button {
                dismissSheet()
            } label: {
                Text(verbatim: "LINK START")
            }
        }
    }
}

enum LoginPath: Hashable {
    case loginEmailVerification
    case loginAuthenticatorVerification
    case registerName
    case registerCredentials
    case registerVerifyInvitationCode
    case registerVerifyEmail
    case registerSuccess
}

#Preview(traits: .commonPreviewTrait) {
    LoginView()
}
