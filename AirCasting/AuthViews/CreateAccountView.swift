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
    @InjectedObject private var userState: UserState
    private let authorizationAPIService: AuthorizationAPIService = AuthorizationAPIService() // [Resolver] Move to dep.

    @State private var isPasswordCorrect = true
    @State private var isEmailCorrect = true
    @State private var isUsernameBlank = false
    @State private var alert: AlertInfo?
    @State private var isLoading = false
    
    @State private var linkActive = false
    @StateObject var SignInPersistanceObserved = SignInPersistance.shared
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    var body: some View {
        LoadingView(isShowing: $isLoading) {
            contentView
        }
    }
}

private extension CreateAccountView {
    var contentView: some View {
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
                        signInButton
                    }
                    Spacer()
                    if userState.currentState == .loggingOut {
                        backgroundSignOutIndication
                    }
                }
                .padding()
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .alert(item: $alert, content: { $0.makeAlert() })
                .onAppear {
                    if userState.currentState == .deletingAccount {
                        alert = InAppAlerts.successfulAccountDeletionConfirmation {
                            userState.currentState = .idle
                        }
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged({ (_) in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
        )
        .background(
            Group {
              signInLink
            }
        )
    }
    
    var progressBar: some View {
        ProgressView(value: 0.8)
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
                        binding: $SignInPersistanceObserved.email)
            .autocapitalization(.none)
    }
    
    var usernameTextfield: some View {
        createTextfield(placeholder: Strings.CreateAccountView.profile,
                        binding: $SignInPersistanceObserved.username)
            .autocapitalization(.none)
    }
    var passwordTextfield: some View {
        createSecuredTextfield(placeholder: Strings.CreateAccountView.password,
                               binding: $SignInPersistanceObserved.password)
    }
    
    var createAccountButton: some View {
        Button(Strings.Commons.continue) {
            checkIfUserInputIsCorrect()
            // Hiding keyboard prevents from double displaying alert
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            if isPasswordCorrect && isEmailCorrect && !isUsernameBlank {
                #warning("Show progress and lock ui to prevent multiple api calls")
                isLoading = true
                let userInput = AuthorizationAPI.SignupUserInput(email: SignInPersistanceObserved.email,
                                                                 username: SignInPersistanceObserved.username,
                                                                 password: SignInPersistanceObserved.password,
                                                                 send_emails: false)
                authorizationAPIService.createAccount(input: userInput) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .failure(let error):
                            self.displayErrorAlert(error: error)
                            Log.warning("Failed to create account \(error)")
                        case .success(let output):
                            completion()
                            Log.info("Successfully created account")
                            do {
                                let user = User(id: output.id, username: output.username, token: output.authentication_token, email: output.email)
                                try userAuthenticationSession.authorise(user)
                            } catch {
                                Log.error("Failed to store credentials \(error)")
                                self.displayErrorAlert(error: .other(error))
                            }
                        }
                        isLoading = false
                    }
                }
            }
        }
        .disabled(userState.currentState == .loggingOut)
        .buttonStyle(BlueButtonStyle())
    }
    
    var signInLink: some View {
        NavigationLink(
            destination: SignInView(completion: completion).environmentObject(lifeTimeEventsProvider),
            isActive: $linkActive,
            label: {
                EmptyView()
            })
    }
    
    var signInButton: some View {
        Button {
            SignInPersistanceObserved.signInActive = true
            SignInPersistanceObserved.clearCredentials()
            linkActive = true
        } label: {
            signingButtonText
        }
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
    
    var backgroundSignOutIndication: some View {
        HStack {
            ActivityIndicator(isAnimating: .constant(userState.currentState == .loggingOut), style: .large)
            Text(Strings.CreateAccountView.loggingOutInBackground)
                .foregroundColor(.aircastingGray)
        }
    }

    func checkIfUserInputIsCorrect() {
        isPasswordCorrect = checkIsPasswordValid(password: SignInPersistanceObserved.password)
        isEmailCorrect = checkIsEmailValid(email: SignInPersistanceObserved.email)
        isUsernameBlank = checkIfBlank(text: SignInPersistanceObserved.username)
    }

    func displayErrorAlert(error: AuthorizationError) {
        switch error {
        case .emailTaken, .invalidCredentials, .usernameTaken, .other, .timeout:
            self.alert = InAppAlerts.createAccountAlert(error: error)
        case .noConnection:
            self.alert = InAppAlerts.noInternetConnection(error: error)
        }
    }
}
