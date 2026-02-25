import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var emailAddress = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
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
                    
                }.buttonStyle(.borderless)
            } footer: {
                Button(.linkStart) {
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close, systemImage: "xmark", role: .close, action: { dismiss() })
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
