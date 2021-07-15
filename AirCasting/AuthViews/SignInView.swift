//
//  SignInView.swift
//  AirCasting
//
//  Created by Lunar on 24/02/2021.
//

import AirCastingStyling
import SwiftUI

extension NSError: Identifiable {}

struct SignInView: View {
    @State var presentingModal = false
    @State var isActive: Bool = false
    let userAuthenticationSession: UserAuthenticationSession
    private let authorizationAPIService = AuthorizationAPIService()
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var task: Cancellable?
    @State private var presentedError: AuthorizationError?
    @State private var isUsernameBlank = false
    @State private var isPasswordBlank = false
    
    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentView
        }
    }
}

private extension SignInView {
    private var contentView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 40) {
                    progressBar
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
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
    }
    
    var progressBar: some View {
        ProgressView(value: 0.825)
            .accentColor(.accentColor)
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
        createTextfield(placeholder: "Profile name",
                        binding: $username)
            .disableAutocorrection(true)
            .autocapitalization(.none)
    }

    var passwordTextfield: some View {
        SecureField("Password", text: $password)
            .padding()
            .frame(height: 50)
            .disableAutocorrection(true)
            .background(Color.aircastingGray.opacity(0.05))
            .border(Color.aircastingGray.opacity(0.1))
    }

    var signinButton: some View {
        Button("Sign in") {
            checkInput()
            if !isPasswordBlank, !isUsernameBlank {
                isActive = true
                
                task = authorizationAPIService.signIn(input: AuthorizationAPI.SigninUserInput(username: username, password: password)) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let output):
                            do {
                                try userAuthenticationSession.authorise(with: output.authentication_token)
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
        .buttonStyle(BlueButtonStyle())
    }
    
    var forgotPassword: some View {
        Button("Forgot password?") {
            presentingModal = true
        }.sheet(isPresented: $presentingModal) {
            let service = EmailResetPasswordService(apiClient: URLSession.shared, validator: DefaultHTTPResponseValidator())
            let controller = EmailForgotPasswordController(resetPasswordService: service)
            let scheduledController = ScheduledForgotPasswordControllerProxy(controller: controller, queue: .main)
            let vm = DefaultForgotPasswordViewModel(controller: scheduledController)
            ForgotPasswordView(viewModel: vm)
        }
        .buttonStyle(BlueTextButtonStyle())
    }
    
    var signupButton: some View {
        NavigationLink(
            destination: CreateAccountView(userAuthenticationSession: userAuthenticationSession),
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
    
    func displayErrorAlert(error: AuthorizationError) -> Alert {
        let title = NSLocalizedString("Login Error", comment: "Login Error alert title")
        switch error {
        case .emailTaken, .invalidCredentials, .usernameTaken:
            return Alert(title: Text(title),
                         message: Text("The profile name or password is incorrect. Please try again. "),
                         dismissButton: .default(Text("Ok")))
            
        case .noConnection:
            return Alert(title: Text("No Internet Connection"),
                         message: Text("Please make sure your device is connected to the internet."),
                         dismissButton: .default(Text("Ok")))
        case .other, .timeout:
            return Alert(title: Text(title),
                         message: Text(error.localizedDescription),
                         dismissButton: .default(Text("Ok")))
        }
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(isActive: true, userAuthenticationSession: UserAuthenticationSession())
    }
}
#endif
