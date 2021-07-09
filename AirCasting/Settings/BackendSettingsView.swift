// Created by Lunar on 28/06/2021.
//

import SwiftUI
import AirCastingStyling

struct BackendSettingsView: View {
    
    let backendURLBuilder = BackendURLValidator()
    
    @Environment(\.presentationMode) var presentationMode
    @State var urlProvider: BaseURLProvider
    @State private var pathText: String = ""
    @State private var portText: String = ""
    @State private var url: URL?
    @State private var buttonEnabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            title
            Spacer()
            createTextfield(placeholder: "Enter url", binding: $pathText)
                .onChange(of: pathText) { _ in
                   updateURL()
                }
            createTextfield(placeholder: "Enter port", binding: $portText)
                .onChange(of: portText) { _ in
                 updateURL()
                }
            Spacer()
            oKButton
            cancelButton
        }
        .padding()
    }
    
    private var title: some View {
        Text(Strings.BackendSettings.backendSettings)
            .font(.title2)
    }
    
    private var oKButton: some View {
        Button {
            urlProvider.baseAppURL = url ?? URL(string: "http://aircasting.org/api")!
            presentationMode.wrappedValue.dismiss()
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
