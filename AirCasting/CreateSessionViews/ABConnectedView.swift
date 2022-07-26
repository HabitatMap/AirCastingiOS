//
//  AirbeamConnectedView.swift
//  AirCasting
//
//  Created by Lunar on 17/02/2021.
//

import AirCastingStyling
import SwiftUI

struct ABConnectedView: View {
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack() {
            ProgressView(value: 0.625)
                .padding(.bottom, 50)
            Image("4-connected")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width - 40, height:  UIScreen.main.bounds.height / 2, alignment: .center)
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            Spacer()
            continueButton
        }
        .padding()
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
}

private extension ABConnectedView {
    var titleLabel: some View {
        Text(Strings.ABConnectedView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.ABConnectedView.message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }

    var continueButton: some View {
        return NavigationLink(
            destination: CreateSessionDetailsView(creatingSessionFlowContinues: $creatingSessionFlowContinues),
            label: {
                Text(Strings.Commons.continue)
            })
            .buttonStyle(BlueButtonStyle())
    }
}
