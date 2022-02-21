//
//  CreateAccountView.swift
//  AirCasting
//
//  Created by Lunar on 23/02/2021.
//
import SwiftUI
import AirCastingStyling
import Resolver

struct CreateAccountView: View {
    
    var completion: () -> Void
    @InjectedObject private var lifeTimeEventsProvider: LifeTimeEventsProvider
    @InjectedObject private var userAuthenticationSession: UserAuthenticationSession
    private let authorizationAPIService: AuthorizationAPIService = AuthorizationAPIService() // [Resolver] Move to dep.

    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordCorrect = true
    @State private var isEmailCorrect = true
    @State private var isUsernameBlank = false
    @State private var presentedError: AuthorizationError?
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 50) {
                    if lifeTimeEventsProvider.hasEverLoggedIn {
                        progressBar.hidden()
                    } else {
                        progressBar
                    }
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
                    Spacer()
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
    
    var progressBar: some View {
        ProgressView(value: 0.825)
            .accentColor(Color.accentColor)
    }
    
    var titleLabel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.CreateAccountView.createTitle_1)
                .font(Fonts.boldTitle1)
                .foregroundColor(.accentColor)
            Text(Strings.CreateAccountView.createTitle_2)
                .font(Fonts.muliHeading2)
                .foregroundColor(.aircastingGray)
        }
    }
    
    var emailTextfield: some View {
        createTextfield(placeholder: Strings.CreateAccountView.email,
                        binding: $email)
            .autocapitalization(.none)
    }
    
    var usernameTextfield: some View {
        createTextfield(placeholder: Strings.CreateAccountView.profile,
                        binding: $username)
            .autocapitalization(.none)
    }
    var passwordTextfield: some View {
        SecureField(Strings.CreateAccountView.password, text: $password)
            .padding()
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .frame(height: 50)
            .background(Color.aircastingGray.opacity(0.05))
            .border(Color.aircastingGray.opacity(0.1))
    }
    
    var createAccountButton: some View {
        Button(Strings.Commons.continue) {
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
                            completion()
                            Log.info("Successfully created account")
                            do {
                                let user = User(id: output.id, username: output.username, token: output.authentication_token, email: output.email)
                                try userAuthenticationSession.authorise(user)
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
            destination: SignInView(completion: completion).environmentObject(lifeTimeEventsProvider),
            label: {
                signingButtonText
            })
    }
    
    var signingButtonText: some View {
        Text(Strings.CreateAccountView.signIn_1)
            .font(Fonts.muliHeading2)
            .foregroundColor(.aircastingGray)
        + Text(" ")
        + Text(Strings.CreateAccountView.signIn_2)
            .font(Fonts.boldHeading2)
            .foregroundColor(.accentColor)
    }

    func checkIfUserInputIsCorrect() {
        isPasswordCorrect = checkIsPasswordValid(password: password)
        isEmailCorrect = checkIsEmailValid(email: email)
        isUsernameBlank = checkIfBlank(text: username)
    }

    func displayErrorAlert(error: AuthorizationError) -> Alert {
        switch error {
        case .emailTaken, .invalidCredentials, .usernameTaken:
            return Alert(title: Text(Strings.CreateAccountView.takenAndOtherTitle),
                         message: Text(error.localizedDescription),
                         dismissButton: .default(Text(Strings.Commons.ok)))

        case .noConnection:
            return Alert(title: Text(Strings.CreateAccountView.noInternetTitle),
                         message: Text(error.localizedDescription),
                         dismissButton: .default(Text(Strings.Commons.ok)))
        case .other, .timeout:
            return Alert(title: Text(Strings.CreateAccountView.takenAndOtherTitle),
                         message: Text(error.localizedDescription),
                         dismissButton: .default(Text(Strings.Commons.ok)))
        }
    }
}
