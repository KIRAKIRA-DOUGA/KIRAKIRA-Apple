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
                Text(.logIn)
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.large)
            .disabled(email.isEmpty || password.isEmpty)
        }
        .padding()
        .navigationTitle(.logIn)
    }
}
