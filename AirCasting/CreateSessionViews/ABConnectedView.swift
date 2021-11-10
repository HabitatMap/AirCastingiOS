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
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }

    var messageLabel: some View {
        Text(Strings.ABConnectedView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }

    var continueButton: some View {
        return NavigationLink(
            destination: CreateSessionDetailsView(
                viewModel: CreateSessionDetailsViewModel(baseURL: baseURL), creatingSessionFlowContinues: $creatingSessionFlowContinues),
            label: {
                Text(Strings.ABConnectedView.continueButton)
            })
            .buttonStyle(BlueButtonStyle())
    }
}
