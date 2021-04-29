//
//  CreateAccountView.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//

import SwiftUI

struct CreateAccountView: View {
    let userAuthenticationSession: UserAuthenticationSession
    private let authorizationAPIService = AuthorizationAPIService()

    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""

    @State private var isPasswordCorrect = true
    @State private var isEmailCorrect = true
    @State private var isUsernameBlank = false
    @State private var presentedError: AuthorizationError?

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
                .alert(item: $presentedError) { error in
                    displayErrorAlert(error: error)
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
}

private extension CreateAccountView {
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
        createTextfield(placeholder: "Profile name",
                        binding: $username)
            .autocapitalization(.none)
    }
    var passwordTextfield: some View {
        SecureField("Password", text: $password)
            .padding()
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .frame(height: 50)
            .background(Color.aircastingGray.opacity(0.05))
            .border(Color.aircastingGray.opacity(0.1))
    }
    
    var createAccountButton: some View {
        Button("Continue") {
            checkIfUserInputIsCorrect()
            // Hiding keyboard prevents from double displaying alert
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            if isPasswordCorrect && isEmailCorrect && !isUsernameBlank {
                #warning("Show progress and lock ui to prevent multiple api calls")
                let userInput = AuthorizationAPI.SignupUserInput(email: email,
                                                                username: username,
                                                                password: password,
                                                                send_emails: false)
                authorizationAPIService.createAccount(input: userInput) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .failure(let error):
                                presentedError = error
                            Log.warning("Failed to create account \(error)")
                        case .success(let output):
                            Log.info("Successfully created account")
                            do {
                                try userAuthenticationSession.authorise(with: output.authentication_token)
                            } catch {
                                Log.error("Failed to store credentials \(error)")
                                presentedError = .other(error)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(BlueButtonStyle())
    }
    
    var signinButton: some View {
        NavigationLink(
            destination: SignInView(userAuthenticationSession: userAuthenticationSession),
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

    func displayErrorAlert(error: AuthorizationError) -> Alert {
        let title = NSLocalizedString("Cannot create account", comment: "Cannot create account alert title")
        switch error {
        case .emailTaken, .invalidCredentials, .usernameTaken:
            return Alert(title: Text(title),
                         message: Text("Email or profile name is already in use. Please try again."),
                         dismissButton: .default(Text("Ok")))

        case .noConnection:
            return Alert(title: Text("No Internet Connection"),
                         message: Text("Please, make sure your device is connected to the internet."),
                         dismissButton: .default(Text("Ok")))
        case .other, .timeout:
            return Alert(title: Text(title),
                         message: Text(error.localizedDescription),
                         dismissButton: .default(Text("Ok")))
        }
    }
}

#if DEBUG
struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView(userAuthenticationSession: UserAuthenticationSession())
    }
}
#endif
