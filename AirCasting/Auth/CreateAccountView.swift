//
//  CreateAccountView.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import SwiftUI

struct CreateAccountView: View {
    
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var task: Any?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 50) {
                titleLabel
                VStack(spacing: 20) {
                    emailTextfield
                    usernameTextfield
                    passwordTextfield
                }
                VStack(spacing: 25) {
                    createAccountButton
                    signinButton
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    var titleLabel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Create account")
                .font(Font.moderate(size: 32,
                                    weight: .bold))
                .foregroundColor(.accentColor)
            Text("to record and map your envitonment")
                .font(Font.muli(size: 16))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var emailTextfield: some View {
        createTextfield(placeholder: "Email",
                        binding: $email)
    }
    var usernameTextfield: some View {
        createTextfield(placeholder: "Username",
                        binding: $username)
    }
    var passwordTextfield: some View {
        SecureField("Password", text: $password)
            .padding()
            .frame(height: 50)
            .background(Color.aircastingGray.opacity(0.05))
            .border(Color.aircastingGray.opacity(0.1))
    }
    
    var createAccountButton: some View {
        Button("Continue") {
            let userInfo = AuthorizationAPI.SignupUserInput(email: email,
                                                      username: username,
                                                      password: password,
                                                      send_emails: false)
            let userInput = AuthorizationAPI.SignupAPIInput(user: userInfo)
            task = AuthorizationAPI.createAccount(input: userInput)
                .sink { (completion) in
                    switch completion {
                    case .finished:
                        print("Success")
                    case .failure(let error):
                        print("ERROR: \(error)")
                    }
                } receiveValue: { (output) in
                    print(output)
                }
            
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var signinButton: some View {
        NavigationLink(
            destination: SignInView(),
            label: {
                signingButtonText
            })
    }
    
    var signingButtonText: some View {
        Text("Already have an account? ")
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
            
            + Text("Sign in")
            .font(Font.moderate(size: 16, weight: .bold))
            .foregroundColor(.accentColor)
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
