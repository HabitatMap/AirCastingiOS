//
//  AirbeamConnectedView.swift
//  AirCasting
//
//  Created by Lunar on 17/02/2021.
//

import SwiftUI

struct ABConnectedView: View {
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var sessionContext: CreateSessionContext
    @Binding var creatingSessionFlowContinues : Bool

    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.625)
            Image("4-connected")
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
        }
        .padding()
    }
}

private extension ABConnectedView {
    var titleLabel: some View {
        Text("AirBeam connected")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    var messageLabel: some View {
        Text("Your AirBeam is connected to your phone and ready to take some measurements.")
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }
    var continueButton: some View {
        let sessionCreator: SessionCreator
        if sessionContext.sessionType == .mobile {
            sessionCreator = MobilePeripheralSessionCreator(
                mobilePeripheralSessionManager: bluetoothManager.mobilePeripheralSessionManager, measurementStreamStorage: CoreDataMeasurementStreamStorage(
                    persistenceController: persistenceController),
                userAuthenticationSession: userAuthenticationSession)
        } else {
            sessionCreator = AirBeamFixedSessionCreator(
                measurementStreamStorage: CoreDataMeasurementStreamStorage(
                    persistenceController: persistenceController),
                userAuthenticationSession: userAuthenticationSession)
        }
        return NavigationLink(
            destination: CreateSessionDetailsView(
                sessionCreator: sessionCreator,
                creatingSessionFlowContinues: $creatingSessionFlowContinues),
            label: {
                Text("Continue")
            })
            .buttonStyle(BlueButtonStyle())
    }
}

#if DEBUG
struct AirbeamConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        ABConnectedView(creatingSessionFlowContinues: .constant(true))
            .environmentObject(PersistenceController())
            .environmentObject(UserAuthenticationSession())
            .environmentObject(BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())))
    }
}
#endif
