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

    @State private var isPasswordCorrect = true
    @State private var isEmailCorrect = true
    @State private var isEmailBlank = false
    @State private var isUsernameBlank = false
    @State private var isPasswordBlank = false
    
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 50) {
                    titleLabel
                    VStack(spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 5) {
                            emailTextfield
                                .keyboardType(.emailAddress)
                            if !isEmailCorrect {
                                errorMessage(text: AuthErrors.incorrectEmail.localizedDescription)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            usernameTextfield
                            if isUsernameBlank {
                                errorMessage(text: AuthErrors.emptyTextfield.localizedDescription)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            passwordTextfield
                            if !isPasswordCorrect {
                                errorMessage(text: AuthErrors.passwordTooShort.localizedDescription)
                            }
                        }
                    }
                    VStack(spacing: 25) {
                        createAccountButton
                        signinButton
                    }
                }
                .padding()
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .simultaneousGesture(

    DragGesture(minimumDistance: 2, coordinateSpace: .global)
        .onChanged({ (_) in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
)
    }
    
    var titleLabel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Create account")
                .font(Font.moderate(size: 32,
                                    weight: .bold))
                .foregroundColor(.accentColor)
            Text("to record and map your environment")
                .font(Font.muli(size: 16))
                .foregroundColor(.aircastingGray)
        }
    }
    
    var emailTextfield: some View {
        createTextfield(placeholder: "Email",
                        binding: $email)
            .autocapitalization(.none)
    }
    
    var usernameTextfield: some View {
        createTextfield(placeholder: "Username",
                        binding: $username)
            .autocapitalization(.none)
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
            checkIfUserInputIsCorrect()
            
            if isPasswordCorrect && isEmailCorrect && !isUsernameBlank {
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
                        UserDefaults.authToken = output.authentication_token
                    }
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
    func checkIfUserInputIsCorrect() {
        isPasswordCorrect = checkIsPasswordValid(password: password)
        isEmailCorrect = checkIsEmailValid(email: email)
        isUsernameBlank = checkIfBlank(text: username)
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
