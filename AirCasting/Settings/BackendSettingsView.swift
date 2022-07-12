// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

struct BackendSettingsView: View {
    private let backendURLBuilder = BackendURLValidator()
    
    @Environment(\.presentationMode) var presentationMode
    @State private var pathText: String = ""
    @State private var portText: String = ""
    @State private var url: URL?
    @State private var alertPresented = false
    
    @InjectedObject private var userState: UserState
    @Injected private var logoutController: LogoutController
    @Injected private var urlProvider: URLProvider
    
    private var urlWithoutPort: String? {
        let components = URLComponents(url: urlProvider.baseAppURL, resolvingAgainstBaseURL: false)!
        return components.host
    }

    private var port: Int? {
        let components = URLComponents(url: urlProvider.baseAppURL, resolvingAgainstBaseURL: false)!
        return components.port
    }

    @State private var buttonEnabled: Bool = false
    
    var body: some View {
        ZStack {
            XMarkButton()
            VStack(alignment: .leading) {
                title
                Spacer()
                createTextfield(placeholder: "\(Strings.BackendSettings.currentURL): \(urlWithoutPort!)", binding: $pathText)
                    .onChange(of: pathText) { _ in
                        updateURL()
                    }
                createTextfield(placeholder: "\(Strings.BackendSettings.currentPort): \(port ?? 80)", binding: $portText)
                    .onChange(of: portText) { _ in
                        updateURL()
                    }
                Spacer()
                oKButton
                cancelButton
            }
            .alert(isPresented: $alertPresented, content: {
                Alert(title: Text(Strings.BackendSettings.alertTitle), message: Text(Strings.BackendSettings.alertMessage),  dismissButton: .default(Text(Strings.Commons.ok)))
            })
            .padding()
        }
        
    }
    
    private var title: some View {
        Text(Strings.BackendSettings.backendSettings)
            .foregroundColor(.darkBlue)
            .font(Fonts.muliSemiboldTitle1)
    }
    
    private var oKButton: some View {
        Button {
            urlProvider.baseAppURL = url ?? URL(string: "http://aircasting.org/")!
            presentationMode.wrappedValue.dismiss()
            do {
                userState.currentState = .loggingOut
                try logoutController.logout {
                    userState.currentState = .idle
                }
            } catch {
                alertPresented = true
                userState.currentState = .idle
                Log.info("Error when logging out - \(error)")
            }
        } label: {
            Text(Strings.Commons.ok)
        }.buttonStyle(BlueButtonStyle())
            .disabled(!buttonEnabled)
    }
    
    private var cancelButton: some View {
        Button(Strings.Commons.cancel) {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(BlueTextButtonStyle())
    }
    
    private func updateURL() {
        do {
            try url = backendURLBuilder.createURL(url: pathText, port: portText)
            buttonEnabled = true
        } catch {
            buttonEnabled = false
        }
    }
}
