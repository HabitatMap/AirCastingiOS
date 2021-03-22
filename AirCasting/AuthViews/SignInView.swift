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
    @State private var wrongInputError = false
    @State private var isUsernameBlank = false
    @State private var isPasswordBlank = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 40) {
                    titleLabel
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            usernameTextfield
                            if isUsernameBlank {
                                errorMessage(text: AuthErrors.emptyTextfield.localizedDescription)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            passwordTextfield
                            if isPasswordBlank {
                                errorMessage(text: AuthErrors.emptyTextfield.localizedDescription)
                            }
                        }
                    }
                    signinButton
                    signupButton
                }
                .padding()
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .alert(isPresented: $wrongInputError) { () -> Alert in
                    Alert(title: Text("Sign in error"),
                          message: Text("Please, check if your email and password are correct and try again."),
                          dismissButton: .default(Text("Ok")))
                }
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
            .autocapitalization(.none)
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
            checkInput()
            if !isPasswordBlank && !isUsernameBlank {
                task = AuthorizationAPI.signIn(input: AuthorizationAPI.SigninUserInput(username: username,
                                                                                       password: password))
                    .sink { (completion) in
                        switch completion {
                        case .finished:
                            print("Success")
                        case .failure(let error):
                            wrongInputError = true
                            print("ERROR: \(error.localizedDescription)")
                        }
                    } receiveValue: { (output) in
                        UserDefaults.authToken = output.authentication_token
                        print(output)
                    }
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
    
    func checkInput() {
        isPasswordBlank = checkIfBlank(text: password)
        isUsernameBlank = checkIfBlank(text: username)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
