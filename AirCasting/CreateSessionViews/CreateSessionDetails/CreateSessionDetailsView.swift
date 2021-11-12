//  Created by Anna Olak on 24/02/2021.
//
import AirCastingStyling
import SwiftUI

struct CreateSessionDetailsView: View {
    
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @StateObject var viewModel: CreateSessionDetailsViewModel
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 25) {
                        ProgressView(value: 0.75)
                        titleLabel
                        VStack(spacing: 20) {
                            createTextfield(placeholder: Strings.CreateSessionDetailsView.sessionNamePlaceholder, binding: $viewModel.sessionName)
                            createTextfield(placeholder: Strings.CreateSessionDetailsView.sessionTagPlaceholder, binding: $viewModel.sessionTags)
                        }
                        if sessionContext.sessionType == SessionType.fixed {
                            placementPicker
                            transmissionTypePicker
                            if viewModel.shouldShowCompleteCredentials() {
                                providePasswordTitle
                                if #available(iOS 15.0, *) {
                                    createTextfield(placeholder: Strings.WifiPopupView.wifiPlaceholder, binding: $viewModel.wifiSSID)
                                        .onSubmit { viewModel.isSSIDTextfieldDisplayed = false }
                                } else {
                                    createTextfield(placeholder: Strings.WifiPopupView.wifiPlaceholder, binding: $viewModel.wifiSSID)
                                }
                                createTextfield(placeholder: Strings.WifiPopupView.passwordPlaceholder, binding: $viewModel.wifiPassword)
                            } else if viewModel.isWiFi {
                                provideNameAndPasswordTitle
                                createTextfield(placeholder: Strings.WifiPopupView.passwordPlaceholder, binding: $viewModel.wifiPassword)
                                connectToDifferentWifi
                            }
                        }
                        Spacer()
                        continueButton
                    }
                .padding()
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
            .background(navigation)
        }
        .onAppear { viewModel.onScreenEnter() }
    }
}

private extension CreateSessionDetailsView {
    
    var navigation: some View {
        ZStack {
            NavigationLink(
                destination: ChooseCustomLocationView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                      sessionName: $viewModel.sessionName, baseURL: viewModel.baseURL),
                isActive: $viewModel.isLocationSessionDetailsActive,
                label: {
                    EmptyView()
                }
            )
            NavigationLink(
                destination: ConfirmCreatingSessionView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                        baseURL: viewModel.baseURL, sessionName: viewModel.sessionName),
                isActive: $viewModel.isConfirmCreatingSessionActive,
                label: {
                    EmptyView()
                }
            )
        }
    }
    
    var continueButton: some View {
        Button(action: {
            let updatedContext = viewModel.onContinueClick(sessionContext: sessionContext)
            sessionContext.ovverride(sessionContext: updatedContext)
        }, label: {
            Text(Strings.CreateSessionDetailsView.continueButton)
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(BlueButtonStyle())
        .disabled(viewModel.isConfirmCreatingSessionActive)
    }

    var titleLabel: some View {
        Text(Strings.CreateSessionDetailsView.title)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }

    var placementPicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.CreateSessionDetailsView.placementPicker_1)
                .font(Fonts.boldHeading1)
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $viewModel.isIndoor, label: Text("")) {
                Text(Strings.CreateSessionDetailsView.placementPicker_2).tag(true)
                Text(Strings.CreateSessionDetailsView.placementPicker_3).tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    var transmissionTypePicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.CreateSessionDetailsView.transmissionPicker)
                .font(Fonts.boldHeading1)
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $viewModel.isWiFi, label: Text("")) {
                Text(Strings.CreateSessionDetailsView.wifiText).tag(true)
                Text(Strings.CreateSessionDetailsView.cellularText).tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    var providePasswordTitle: some View {
        Text(Strings.WifiPopupView.passwordTitle)
            .font(Fonts.heavyTitle3)
            .foregroundColor(.darkBlue)
    }
    
    var provideNameAndPasswordTitle: some View {
        Text("\(Strings.WifiPopupView.nameAndPasswordTitle_1) \(viewModel.wifiSSID) \(Strings.WifiPopupView.nameAndPasswordTitle_2)")
            .font(Fonts.heavyTitle3)
            .foregroundColor(.darkBlue)
    }
    
    var connectToDifferentWifi: some View {
        Button(Strings.WifiPopupView.differentNetwork) {
            viewModel.connectToOtherNetworkClick()
        }
    }
}

