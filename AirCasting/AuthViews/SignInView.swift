//
//  SignInView.swift
//  AirCasting
//
//  Created by Lunar on 24/02/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

extension NSError: Identifiable {}

struct SignInView: View {
    
    @State var presentingModal = false
    @InjectedObject private var lifeTimeEventsProvider: LifeTimeEventsProvider
    var completion: () -> Void
    
    @State var isActive: Bool
    @InjectedObject private var userAuthenticationSession: UserAuthenticationSession
    @InjectedObject private var userState: UserState
    private let authorizationAPIService = AuthorizationAPIService()
    @State private var task: Cancellable? = nil
    @State private var presentedError: AuthorizationError? = nil
    @State private var isUsernameBlank = false
    @State private var isPasswordBlank = false
    
    @StateObject var signInPersistanceObserved = SignInPersistance.shared
    
    init(completion: @escaping () -> Void, active: Bool = false) {
        _isActive = State(initialValue: active)
        self.completion = completion
    }
    
    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentView
                .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
        }
    }
}

private extension SignInView {
    private var contentView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Image("dashboard-background-thing")
                    .offset(x: 0, y: 40)
                VStack(alignment: .leading, spacing: 40) {
                    if lifeTimeEventsProvider.hasEverLoggedIn {
                        progressBar.hidden()
                    } else {
                        progressBar
                    }
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
                    VStack(spacing: 10) {
                        signinButton
                        forgotPassword
                        signupButton
                    }
                    Spacer()
                    if userState.currentState == .loggingOut {
                        backgroundSignOutIndication
                    }
                }
                .padding()
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .alert(item: $presentedError) { error in
                    displayErrorAlert(error: error)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    })
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    var progressBar: some View {
        ProgressView(value: 0.825)
            .accentColor(.accentColor)
    }
    
    var titleLabel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.SignInView.signIn_1)
                .font(Fonts.moderateBoldTitle1)
                .foregroundColor(.accentColor)
            Text(Strings.SignInView.signIn_2)
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(.aircastingGray)
        }
    }
    
    var usernameTextfield: some View {
        createTextfield(placeholder: Strings.SignInView.usernameField,
                        binding: $signInPersistanceObserved.username,
                        isInputValid: isUsernameBlank)
        .font(Fonts.moderateRegularHeading2)
        .disableAutocorrection(true)
        .autocapitalization(.none)
    }
    
    var passwordTextfield: some View {
        createSecuredTextfield(placeholder: Strings.SignInView.passwordField,
                               binding: $signInPersistanceObserved.password,
                               isInputValid: isPasswordBlank)
    }
    
    var signinButton: some View {
        Button(Strings.SignInView.signIn_1) {
            checkInput()
            if !isPasswordBlank, !isUsernameBlank {
                isActive = true
                
                task = authorizationAPIService.signIn(input: AuthorizationAPI.SigninUserInput(username: signInPersistanceObserved.username, password: signInPersistanceObserved.password)) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let output):
                            do {
                                let user = User(id: output.id, username: output.username, token: output.authentication_token, email: output.email)
                                try userAuthenticationSession.authorise(user)
                                completion()
                                Log.info("Successfully logged in")
                            } catch {
                                assertionFailure("Failed to store credentials \(error)")
                                presentedError = .other(error)
                            }
                        case .failure(let error):
                            Log.warning("Failed to login \(error)")
                            presentedError = error
                        }
                        isActive = false
                    }
                }
            }
        }
        .font(Fonts.muliBoldHeading1)
        .disabled(userState.currentState == .loggingOut)
        .buttonStyle(BlueButtonStyle())
    }
    
    var forgotPassword: some View {
        Button(Strings.SignInView.forgotPasswordButton) {
            presentingModal = true
        }.sheet(isPresented: $presentingModal) {
            // [Resolver] - Move VM creation inside the View
            let controller = EmailForgotPasswordController(resetPasswordService: EmailResetPasswordService())
            let scheduledController = ScheduledForgotPasswordControllerProxy(controller: controller, queue: .main)
            let vm = DefaultForgotPasswordViewModel(controller: scheduledController)
            ForgotPasswordView(viewModel: vm)
        }
        .font(Fonts.moderateBoldHeading1)
        .buttonStyle(BlueTextButtonStyle())
    }
    
    var signupButton: some View {
        Button {
            signInPersistanceObserved.credentialsScreen = .createAccount
            signInPersistanceObserved.clearCredentials()
        } label: {
            signupButtonText
        }
    }
    
    var signupButtonText: some View {
        Text(Strings.SignInView.signUpButton_1)
            .font(Fonts.muliRegularHeading3)
            .foregroundColor(.aircastingGray)
        + Text(Strings.SignInView.signUpButton_2)
            .font(Fonts.moderateBoldHeading1)
            .foregroundColor(.accentColor)
    }
    
    var backgroundSignOutIndication: some View {
        HStack {
            ActivityIndicator(isAnimating: .constant(userState.currentState == .loggingOut), style: .large)
            Text(Strings.CreateAccountView.loggingOutInBackground)
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(.aircastingGray)
        }
    }
    
    func checkInput() {
        isPasswordBlank = checkIfBlank(text: signInPersistanceObserved.password)
        isUsernameBlank = checkIfBlank(text: signInPersistanceObserved.username)
    }
    
    func displayErrorAlert(error: AuthorizationError) -> Alert {
        let title = Strings.SignInView.alertTitle
        switch error {
        case .emailTaken, .invalidCredentials, .usernameTaken:
            return Alert(title: Text(title),
                         message: Text(Strings.SignInView.InvalidCredentialText),
                         dismissButton: .default(Text(Strings.Commons.ok)))
            
        case .noConnection:
            return Alert(title: Text(Strings.SignInView.noConnectionTitle),
                         message: Text(Strings.SignInView.noConnectionText),
                         dismissButton: .default(Text(Strings.Commons.ok)))
        case .other, .timeout:
            return Alert(title: Text(title),
                         message: Text(error.localizedDescription),
                         dismissButton: .default(Text(Strings.Commons.ok)))
        }
    }
}
