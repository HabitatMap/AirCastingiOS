//
//  SignInView.swift
//  AirCasting
//
//  Created by Lunar on 24/02/2021.
//

import SwiftUI

struct SignInView: View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var task: Any?
    
    var body: some View {
            VStack(spacing: 40) {
                titleLabel
                VStack(spacing: 20) {
                    usernameTextfield
                    passwordTextfield
                }
                signinButton
                signupButton
            }
            .padding()
            .navigationBarHidden(true)
    }
    
    var titleLabel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sign in")
                .font(Font.moderate(size: 32,
                                    weight: .bold))
                .foregroundColor(.accentColor)
            Text("to record and map your environment")
                .font(Font.muli(size: 16))
                .foregroundColor(.aircastingGray)
        }
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
    var signinButton: some View {
        Button("Sign in") {
            task = AuthorizationAPI.signIn(input: AuthorizationAPI.SigninUserInput(username: username,
                                                                            password: password))
                .sink { (completion) in
                    switch completion {
                    case .finished:
                        print("Success")
                    case .failure(let error):
                        print("ERROR: \(error)")
                    }
                } receiveValue: { (output) in
                    UserDefaults.authToken = output.authentication_token
                    print(output)
                }
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var signupButton: some View {
        NavigationLink(
            destination: CreateAccountView(),
            label: {
                signupButtonText
            })
    }
    
    var signupButtonText: some View {
        Text("First time here? ")
            .font(Font.muli(size: 16))
            .foregroundColor(.aircastingGray)
            
            + Text("Create an account")
            .font(Font.moderate(size: 16, weight: .bold))
            .foregroundColor(.accentColor)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
