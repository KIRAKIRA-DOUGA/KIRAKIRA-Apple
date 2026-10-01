import SwiftUI

@Observable
private final class AuthFlowState {
    var emailAddress = ""
    var password = ""
    var username = ""
    var nickname = ""
    var invitationCode = ""
}

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authManager = AuthManager.shared
    @State private var flow = AuthFlowState()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WizardForm(image: "Logo", title: .logIn, subtitle: .logInDescription) {
                WizardSection {
                    TextField(.emailAddress, text: $flow.emailAddress)
                        .textContentType(.emailAddress)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField(.password, text: $flow.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit(startLogin)
                }

                AuthErrorMessage(message: authManager.errorMessage)

                Button(.createAccount, systemImage: "plus.circle") {
                    authManager.clearError()
                    path.append(AuthPath.registerName)
                }
                .buttonStyle(.borderless)
            } footer: {
                Button(action: startLogin) {
                    if authManager.isLoading { ButtonProgressView() } else { Text(.logIn) }
                }
                .disabled(flow.emailAddress.isEmpty || flow.password.isEmpty || authManager.isLoading)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close, systemImage: "xmark", role: .close, action: { dismiss() })
                }
            }
            .navigationDestination(for: AuthPath.self) { route in
                switch route {
                case .loginEmailVerification:
                    LoginEmailVerificationView(flow: flow, dismissSheet: dismiss)
                case .loginAuthenticatorVerification:
                    LoginAuthenticatorVerificationView(flow: flow, dismissSheet: dismiss)
                case .registerName:
                    RegisterNameView(path: $path, flow: flow)
                case .registerCredentials:
                    RegisterCredentialsView(path: $path, flow: flow)
                case .registerVerifyInvitationCode:
                    RegisterVerifyInvitationCodeView(path: $path, flow: flow)
                case .registerVerifyEmail:
                    RegisterVerifyEmailView(path: $path, flow: flow)
                case .registerSuccess:
                    RegisterSuccessView(dismissSheet: dismiss)
                }
            }
        }
        .onDisappear { authManager.clearError() }
    }

    private func startLogin() {
        Task {
            let email = flow.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            flow.emailAddress = email
            guard let method = await authManager.checkLoginMethod(email: email) else { return }
            switch method {
            case .none:
                if await authManager.login(email: email, password: flow.password) { dismiss() }
            case .email:
                if await authManager.sendVerificationCode(email: email, purpose: .login) {
                    path.append(AuthPath.loginEmailVerification)
                }
            case .totp:
                path.append(AuthPath.loginAuthenticatorVerification)
            }
        }
    }
}

private struct LoginEmailVerificationView: View {
    @Bindable var flow: AuthFlowState
    let dismissSheet: DismissAction
    @State private var authManager = AuthManager.shared
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(
            systemImage: "envelope.badge", title: .verifyIdentity,
            subtitle: .enterVerificationCodeEmailDescription
        ) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
            }
            AuthErrorMessage(message: authManager.errorMessage)
        } footer: {
            Button {
                Task {
                    if await authManager.login(
                        email: flow.emailAddress,
                        password: flow.password,
                        verificationCode: verificationCode
                    ) { dismissSheet() }
                }
            } label: {
                if authManager.isLoading { ButtonProgressView() } else { Text(.logIn) }
            }
            .disabled(verificationCode.count != 6 || authManager.isLoading)

            Button {
                Task { _ = await authManager.sendVerificationCode(email: flow.emailAddress, purpose: .login) }
            } label: {
                Text(.authResendVerificationCode)
            }
            .buttonStyle(.glass)
            .disabled(authManager.isLoading)
        }
    }
}

private struct LoginAuthenticatorVerificationView: View {
    @Bindable var flow: AuthFlowState
    let dismissSheet: DismissAction
    @State private var authManager = AuthManager.shared
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(
            systemImage: "lock.badge.clock", title: .verifyIdentity,
            subtitle: .enterVerificationCodeAuthenticatorDescription
        ) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
            }
            AuthErrorMessage(message: authManager.errorMessage)
        } footer: {
            Button {
                Task {
                    if await authManager.login(
                        email: flow.emailAddress,
                        password: flow.password,
                        clientOtp: verificationCode
                    ) { dismissSheet() }
                }
            } label: {
                if authManager.isLoading { ButtonProgressView() } else { Text(.logIn) }
            }
            .disabled(verificationCode.isEmpty || authManager.isLoading)
        }
    }
}

private struct RegisterNameView: View {
    @Binding var path: NavigationPath
    @Bindable var flow: AuthFlowState
    @State private var authManager = AuthManager.shared

    var body: some View {
        WizardForm(
            systemImage: "person.crop.circle.badge.questionmark", title: .whoAreYou,
            subtitle: .setUpUsernameNickname
        ) {
            WizardSection {
                LabeledContent {
                    TextField(.settingsProfileUsername, text: $flow.username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                } label: {
                    Text(verbatim: "@")
                }
                .fontDesign(.monospaced)

                TextField(.settingsProfileNickname, text: $flow.nickname)
            }
            AuthErrorMessage(message: authManager.errorMessage)
        } footer: {
            Button {
                Task {
                    flow.username = flow.username.trimmingCharacters(in: .whitespacesAndNewlines)
                    if await authManager.isUsernameAvailable(flow.username) {
                        path.append(AuthPath.registerCredentials)
                    }
                }
            } label: {
                if authManager.isLoading { ButtonProgressView() } else { Text(.actionContinue) }
            }
            .disabled(flow.username.isEmpty || authManager.isLoading)
        }
    }
}

private struct RegisterCredentialsView: View {
    @Binding var path: NavigationPath
    @Bindable var flow: AuthFlowState
    @State private var authManager = AuthManager.shared

    var body: some View {
        WizardForm(
            systemImage: "person.crop.circle.badge.plus", title: .registerAccount,
            subtitle: .registerAccountDescription
        ) {
            WizardSection {
                TextField(.emailAddress, text: $flow.emailAddress)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField(.password, text: $flow.password)
                    .textContentType(.newPassword)
            }
            AuthErrorMessage(message: authManager.errorMessage)
        } footer: {
            Button {
                Task {
                    flow.emailAddress = flow.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                    if await authManager.isEmailAvailable(flow.emailAddress) {
                        path.append(AuthPath.registerVerifyInvitationCode)
                    }
                }
            } label: {
                if authManager.isLoading { ButtonProgressView() } else { Text(.actionContinue) }
            }
            .disabled(flow.emailAddress.isEmpty || flow.password.isEmpty || authManager.isLoading)
        }
    }
}

private struct RegisterVerifyInvitationCodeView: View {
    @Binding var path: NavigationPath
    @Bindable var flow: AuthFlowState
    @State private var authManager = AuthManager.shared

    var body: some View {
        WizardForm(systemImage: "gift", title: .verifyInvitationCode, subtitle: .verifyInvitationCodeDescription) {
            WizardSection {
                TextField(.invitationCode, text: $flow.invitationCode)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
            }
            AuthErrorMessage(message: authManager.errorMessage)
        } footer: {
            Button {
                Task {
                    flow.invitationCode = flow.invitationCode
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                    guard await authManager.isInvitationCodeAvailable(flow.invitationCode) else { return }
                    if await authManager.sendVerificationCode(email: flow.emailAddress, purpose: .registration) {
                        path.append(AuthPath.registerVerifyEmail)
                    }
                }
            } label: {
                if authManager.isLoading { ButtonProgressView() } else { Text(.actionContinue) }
            }
            .disabled(flow.invitationCode.isEmpty || authManager.isLoading)
        }
    }
}

private struct RegisterVerifyEmailView: View {
    @Binding var path: NavigationPath
    @Bindable var flow: AuthFlowState
    @State private var authManager = AuthManager.shared
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(
            systemImage: "envelope.badge", title: .verifyEmailAddress,
            subtitle: .enterVerificationCodeEmailDescription
        ) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
            }
            AuthErrorMessage(message: authManager.errorMessage)
        } footer: {
            Button {
                Task {
                    if await authManager.register(
                        username: flow.username,
                        nickname: flow.nickname,
                        email: flow.emailAddress,
                        password: flow.password,
                        invitationCode: flow.invitationCode,
                        verificationCode: verificationCode
                    ) { path.append(AuthPath.registerSuccess) }
                }
            } label: {
                if authManager.isLoading { ButtonProgressView() } else { Text(.actionContinue) }
            }
            .disabled(verificationCode.count != 6 || authManager.isLoading)

            Button {
                Task { _ = await authManager.sendVerificationCode(email: flow.emailAddress, purpose: .registration) }
            } label: {
                Text(.authResendVerificationCode)
            }
            .buttonStyle(.glass)
            .disabled(authManager.isLoading)
        }
    }
}

private struct RegisterSuccessView: View {
    let dismissSheet: DismissAction

    var body: some View {
        WizardForm(
            systemImage: "checkmark.circle", iconStyle: AnyShapeStyle(.green.gradient), title: .registerSuccess,
            subtitle: .registerSuccessDescription
        ) {
            EmptyView()
        } footer: {
            Button(action: { dismissSheet() }) {
                Text(.actionDone)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

private struct AuthErrorMessage: View {
    let message: String?

    var body: some View {
        if let message, !message.isEmpty {
            WizardSection {
                Label {
                    Text(verbatim: message)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                }
                .foregroundStyle(.red)
            }
        }
    }
}

private struct ButtonProgressView: View {
    var body: some View {
        ProgressView()
            .controlSize(.regular)
    }
}

private enum AuthPath: Hashable {
    case loginEmailVerification
    case loginAuthenticatorVerification
    case registerName
    case registerCredentials
    case registerVerifyInvitationCode
    case registerVerifyEmail
    case registerSuccess
}

#Preview(traits: .commonPreviewTrait) {
    AuthView()
}
