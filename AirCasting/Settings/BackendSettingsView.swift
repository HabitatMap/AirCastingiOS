// Created by Lunar on 28/06/2021.
//

import AirCastingStyling
import SwiftUI

struct BackendSettingsView: View {
    let backendURLBuilder = BackendURLValidator()
    
    @Environment(\.presentationMode) var presentationMode
    let logoutController: LogoutController
    @State var urlProvider: BaseURLProvider
    @State private var pathText: String = ""
    @State private var portText: String = ""
    @State private var url: URL?
    @State private var alertPresented = false
    @Binding var isShowingLoadingScreen: Bool
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
        VStack(alignment: .leading) {
            title
            Spacer()
            createTextfield(placeholder: "current url: \(urlWithoutPort!)", binding: $pathText)
                .onChange(of: pathText) { _ in
                    updateURL()
                }
            createTextfield(placeholder: "current port: \(port ?? 80)", binding: $portText)
                .onChange(of: portText) { _ in
                    updateURL()
                }
            Spacer()
            oKButton
            cancelButton
        }.alert(isPresented: $alertPresented, content: {
            Alert(title: Text(Strings.BackendSettings.alertTitle), message: Text(Strings.BackendSettings.alertMessage),  dismissButton: .default(Text(Strings.BackendSettings.Ok)))
        })
        .padding()
    }
    
    private var title: some View {
        Text(Strings.BackendSettings.backendSettings)
            .foregroundColor(.darkBlue)
            .font(Fonts.semiboldTitle1)
    }
    
    private var oKButton: some View {
        Button {
            urlProvider.baseAppURL = url ?? URL(string: "http://aircasting.org/api")!
            presentationMode.wrappedValue.dismiss()
            do {
                isShowingLoadingScreen = true
                try logoutController.logout(onEnd: { isShowingLoadingScreen = false })
            } catch {
                alertPresented = true
                Log.info("Error when logging out - \(error)")
            }
        } label: {
            Text(Strings.BackendSettings.Ok)
        }.buttonStyle(BlueButtonStyle())
            .disabled(!buttonEnabled)
    }
    
    private var cancelButton: some View {
        Button(Strings.BackendSettings.Cancel) {
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
