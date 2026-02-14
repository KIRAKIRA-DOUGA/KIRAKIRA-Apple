import SwiftUI

struct EmailVerifcationView: View {
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(image: "Logo", title: .verifyYourIdentity, subtitle: .verifyEmailDescription) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .textContentType(.oneTimeCode)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numberPad)
            }
            Button(.resend) {

            }.buttonStyle(.borderless)
        } footer: {
            Button(.linkStart) {

            }
        }
    }
}

struct TotpVerifcationView: View {
    @State private var verificationCode = ""

    var body: some View {
        WizardForm(image: "Logo", title: .verifyYourIdentity, subtitle: .verifyTotpDescription) {
            WizardSection {
                TextField(.verificationCode, text: $verificationCode)
                    .textContentType(.oneTimeCode)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numbersAndPunctuation)
            }
        } footer: {
            Button(.linkStart) {

            }
        }
    }
}

struct LoginView: View {
    @State private var emailAddress = ""
    @State private var password = ""

    var body: some View {
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
    }
}

#Preview {
    EmailVerifcationView()
}
