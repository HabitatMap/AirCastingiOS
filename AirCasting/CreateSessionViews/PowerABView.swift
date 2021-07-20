//
//  PowerABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI
import AirCastingStyling

struct PowerABView: View {
    @State private var showAlert = false
    @StateObject private var locationTracker = LocationTracker()
    @Binding var creatingSessionFlowContinues : Bool
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
            Alert(
                title: Text("Location alert"),
                message: Text("Please go to settings and allow location first."),
                primaryButton: .cancel(Text("OK")) { },
                secondaryButton: .default(Text("Settings"), action: {
                    goToLocationAuthSettings()
                })
            )
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
        Text("Power on your AirBeam")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("If using AirBeam 2, wait for the conncection indicator to change from red to green before continuing.")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)

    }
    var continueButton: some View {
        NavigationLink(destination: SelectPeripheralView(creatingSessionFlowContinues: $creatingSessionFlowContinues, urlProvider: urlProvider)) {
            Text("Continue")
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
