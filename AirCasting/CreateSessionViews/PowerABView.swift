//
//  PowerABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import AirCastingStyling
import SwiftUI

struct PowerABView: View {
    @State private var showAlert = false
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var sessionContext: CreateSessionContext
    let urlProvider: BaseURLProvider

    var body: some View {
        VStack(spacing: 45) {
            ProgressView(value: 0.25)
            Image("2-power")
                .resizable()
                .scaledToFit()
            HStack() {
                titleLabel
                Spacer()
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .alert(isPresented: $showAlert) {
            Alert.locationAlert
        }
        .padding()
        .onAppear(perform: {
            sessionContext.deviceType = .AIRBEAM3
        })
    }

    var titleLabel: some View {
        Text(Strings.PowerABView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }

    //stays here for maybe future needs
    var messageLabel: some View {
        Text(Strings.PowerABView.messageText)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }

    var continueButton: some View {
        NavigationLink(destination: SelectPeripheralView(SDClearingRouteProcess: false, creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider)) {
            Text(Strings.PowerABView.continueButton)
                .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
struct PowerABView_Previews: PreviewProvider {
    static var previews: some View {
        PowerABView(creatingSessionFlowContinues: .constant(true), urlProvider: DummyURLProvider())
    }
}
#endif
