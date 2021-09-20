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
    let baseURL: BaseURLProvider
    
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
        Text(Strings.ABConnectedView.title)
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.ABConnectedView.message)
            .font(Font.moderate(size: 18,
                                weight: .regular))
            .foregroundColor(.aircastingGray)
    }

    var continueButton: some View {
        return NavigationLink(
            destination: CreateSessionDetailsView(
                creatingSessionFlowContinues: $creatingSessionFlowContinues, baseURL: baseURL),
            label: {
                Text(Strings.ABConnectedView.continueButton)
            })
            .buttonStyle(BlueButtonStyle())
    }
}
