import SwiftUI

struct LoginView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack {
            TextField(.email, text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(.quinary)
                .clipShape(.capsule)

            SecureField(.password, text: $password)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .padding()
                .background(.quinary)
                .clipShape(.capsule)

            if let error = globalStateManager.authManager.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    let _ = await globalStateManager.authManager.login(email: email, password: password)
                }
            } label: {
                if globalStateManager.authManager.isLoading {
                    ProgressView()
                } else {
                    Text(.logIn)
                }
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.large)
            .disabled(globalStateManager.authManager.isLoading || email.isEmpty || password.isEmpty)
        }
        .padding()
        .navigationTitle(.logIn)
    }
}
