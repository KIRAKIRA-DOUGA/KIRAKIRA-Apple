//
//  LoginView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/12/26.
//

import SwiftUI

struct LoginView: View {
    @State private var emailAddress = ""
    @State private var password = ""
    
    var body: some View {
        WizardForm(image: "Logo", title: .logIn, subtitle: .welcomeBack) {
            WizardSection {
                TextField(.emailAddress, text: $emailAddress)
                    .textContentType(.emailAddress)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField(.password, text: $password)
                    .textContentType(.password)
            }
            
            Button("注册", systemImage: "plus.circle") {
                
            }.buttonStyle(.borderless)
        } footer: {
            Button(.linkStart) {
                
            }
        }
    }
}

#Preview {
    LoginView()
}
