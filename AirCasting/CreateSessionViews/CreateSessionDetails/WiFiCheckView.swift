// Created by Lunar on 25/08/2022.
//

import SwiftUI
import AirCastingStyling

struct WiFiCheckView: View {
    
    @StateObject var viewModel: WiFiCheckViewModel
    
    init(wifiSSID: String, wifiPassword: String) {
        self._viewModel = .init(wrappedValue: .init(wifiSSID: wifiSSID, wifiPassword: wifiPassword))
    }
    
    var body: some View {
        VStack {
            Text("Wi-Fi connectivity checking...")
                .font(Fonts.muliHeavyTitle1)
                .foregroundColor(.darkBlue)
            Spacer()
            Image(systemName: "wifi.circle")
                .resizable()
                .font(.largeTitle)
                .scaledToFit()
                .foregroundColor(viewModel.finalColor)
            Spacer()
            continueButton
        }
        .padding()
        .onAppear {
            viewModel.connectToWiFi()
        }
    }
}


extension WiFiCheckView {
    
    var continueButton: some View {
        Button(action: {
            //
        }, label: {
            Text(Strings.Commons.continue)
                .font(Fonts.muliBoldHeading1)
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(BlueButtonStyle())
    }
}
