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
    @StateObject private var locationTracker = LocationTracker()
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var sessionContext: CreateSessionContext
    let urlProvider: BaseURLProvider
    private var continueButtonEnabled: Bool {
        locationTracker.locationGranted == .granted
    }

    var body: some View {
        VStack(spacing: 45) {
            ProgressView(value: 0.25)
            Image("2-power")
            VStack(alignment: .leading, spacing: 13) {
                titleLabel
                messageLabel
            }
            continueButton
                .buttonStyle(BlueButtonStyle())
        }.alert(isPresented: $showAlert) {
            Alert.locationAlert
        }

        .padding()
        .onAppear(perform: {
            locationTracker.requestAuthorisation()
            sessionContext.deviceType = .AIRBEAM3
        })
        .onChange(of: locationTracker.locationGranted) { newValue in
            showAlert = (newValue == .denied)
        }
    }

    var titleLabel: some View {
        Text(Strings.PowerABView.title)
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.PowerABView.messageText)
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }

    var continueButton: some View {
        NavigationLink(destination: SelectPeripheralView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider)) {
            Text(Strings.PowerABView.continueButton)
                .frame(maxWidth: .infinity)
        }.disabled(!continueButtonEnabled)
    }
}

#if DEBUG
struct PowerABView_Previews: PreviewProvider {
    static var previews: some View {
        PowerABView(creatingSessionFlowContinues: .constant(true), urlProvider: DummyURLProvider())
    }
}
#endif
