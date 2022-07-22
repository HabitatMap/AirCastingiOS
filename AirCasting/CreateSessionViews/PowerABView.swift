//
//  PowerABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import AirCastingStyling
import SwiftUI
import Resolver

struct PowerABView: View {
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var sessionContext: CreateSessionContext

    var body: some View {
        VStack() {
            ProgressView(value: 0.25)
                .padding(.bottom, 50)
            Image("2-power")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width - 40, height:  UIScreen.main.bounds.height / 2, alignment: .center)
            HStack() {
                titleLabel
                Spacer()
            }
            Spacer()
            continueButton
                .buttonStyle(BlueButtonStyle())
        }
        .padding()
        .onAppear(perform: { sessionContext.deviceType = .AIRBEAM3 })
        .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
    }

    var titleLabel: some View {
        Text(Strings.PowerABView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }

    //stays here for maybe future needs
    var messageLabel: some View {
        Text(Strings.PowerABView.messageText)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }

    var continueButton: some View {
        NavigationLink(destination: SelectPeripheralView(SDClearingRouteProcess: false, creatingSessionFlowContinues: $creatingSessionFlowContinues)) {
            Text(Strings.Commons.continue)
                .font(Fonts.muliBoldHeading1)
                .frame(maxWidth: .infinity)
        }
    }
}
