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
            VStack(spacing: 20) {
                turnOnButton
                continueButton
            }
        }
        .padding()
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .background(locationPickerLink)
        .onAppear {
            viewModel.requestLocationAuthorisation()
        }
        .onChange(of: viewModel.shouldShowAlert) { newValue in
            if newValue { viewModel.alert = InAppAlerts.locationAlert() }
        }
        .onAppCameToForeground {
            // The aim of this is to allow user to choose location option from native Apple location popup
            // It is the case when the user first nedded to turn on system location services at all.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.requestLocationAuthorisation()
            }
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
    
    var turnOnButton: some View {
        Button(action: {
            viewModel.onTurnOnButtonClicked()
        }, label: {
            Text(Strings.TurnOnLocationView.continueButton)
        })
        .frame(maxWidth: .infinity)
        .buttonStyle(BlueButtonStyle())
    }
    
    var continueButton: some View {
        Button(action: {
            viewModel.onContinueButtonClick()
        }, label: {
            Text(Strings.Commons.continue)
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
}
