// Created by Lunar on 27/01/2022.
//

import AirCastingStyling
import SwiftUI

struct TurnOnLocationFixedView: View {
    @Binding var creatingSessionFlowContinues: Bool
    @StateObject var viewModel: TurnOnLocationFixedViewModel
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.125)
            Image("location-1")
                .resizable()
                .scaledToFit()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
        }
        .padding()
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .background(
            Group {
                locationPickerLink
                createSesssionLink
            }
        )
        .onAppear {
            viewModel.requestLocationAuthorisation()
        }
        .onChange(of: viewModel.shouldShowAlert) { newValue in
            if newValue { viewModel.alert = InAppAlerts.locationAlert() }
        }
    }
    
    var titleLabel: some View {
        Text(Strings.TurnOnLocationView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.TurnOnLocationView.messageText)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
            .lineSpacing(10.0)
    }
    
    var continueButton: some View {
        Button(action: {
            viewModel.onButtonClick()
        }, label: {
            Text(Strings.TurnOnLocationView.continueButton)
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
    }
    
    var locationPickerLink: some View {
        NavigationLink(
            destination: ChooseCustomLocationView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                  sessionName: viewModel.getSessionName),
            isActive: $viewModel.isLocationSessionDetailsActive,
            label: {
                EmptyView()
            }
        )
    }
    
    var createSesssionLink: some View {
        NavigationLink(
            destination: ConfirmCreatingSessionView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                    sessionName: viewModel.getSessionName),
            isActive: $viewModel.isConfirmCreatingSessionActive,
            label: {
                EmptyView()
            }
        )
    }
}
