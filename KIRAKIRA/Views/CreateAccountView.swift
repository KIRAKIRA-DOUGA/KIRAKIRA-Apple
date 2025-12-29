//
//  CreateAccountView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/26.
//

import SwiftUI

struct CreateAccountView: View {
    @State private var emailAddress = ""
    @State private var password = ""
    @State private var password2 = ""
    
    var body: some View {
        WizardForm(systemImage: "person.badge.plus", title: .createAccount) {
            WizardSection {
                TextField(.emailAddress, text: $emailAddress)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField(.password, text: $password)
                    .textContentType(.newPassword)

                SecureField(.reenterPassword, text: $password2)
                    .textContentType(.newPassword)
            }
        } footer: {
            Button(.actionContinue) {
                
            }.disabled(emailAddress.isEmpty || password.isEmpty || password2.isEmpty || password != password2)
        }
    }
}

#Preview {
    CreateAccountView()
}
