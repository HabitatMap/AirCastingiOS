//  Created by Anna Olak on 24/02/2021.
//
import AirCastingStyling
import SwiftUI
import Resolver

struct CreateSessionDetailsView: View {
    
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @StateObject private var viewModel: CreateSessionDetailsViewModel = .init()
    @Binding var creatingSessionFlowContinues: Bool
    @Injected private var locationTracker: LocationTracker
    private var shouldTrackLocation: Bool { sessionContext.sessionType == .fixed || !sessionContext.locationless }
    
    init(creatingSessionFlowContinues: Binding<Bool>) {
        self._creatingSessionFlowContinues = creatingSessionFlowContinues
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 25) {
                    ProgressView(value: 0.75)
                    titleLabel
                    VStack(alignment: .leading) {
                        sessionNameField
                        if viewModel.shouldShowError { errorMessage(text: Strings.EditSession.erorr) }
                        sessionTagsField
                            .padding(.top, 20)
                    }
                    if sessionContext.sessionType == SessionType.fixed { fixedSessionDetails }
                    Spacer()
                    continueButton
                        .onTapGesture {
                            viewModel.areCredentialsEmpty() ? (viewModel.showAlertAboutEmptyCredentials = true) : nil
                        }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
            .alert(isPresented: $viewModel.showAlertAboutEmptyCredentials, content: {
                Alert(title: Text(Strings.CreateSessionDetailsView.wifiAlertTitle),
                      message: Text(Strings.CreateSessionDetailsView.wifiAlertMessage),
                      dismissButton: .default(Text(Strings.Commons.continue)))
            })
            .background(navigation)
            .background(Color.aircastingBackground.ignoresSafeArea())
        }
        .onAppear {
            viewModel.onScreenEnter()
            if shouldTrackLocation {
                // We are adding this here to show the most recent location on the map on fixed session location picker screen
                // and on the map for mobile session confirmation screen
                locationTracker.start()
            }
        }
        .onDisappear {
            if shouldTrackLocation {
                locationTracker.stop()
            }
        }
        .onChange(of: viewModel.sessionName) { _ in
            viewModel.showErrorIndicator = false
        }
    }
}

private extension CreateSessionDetailsView {
    
    var fixedSessionDetails: some View {
        VStack(alignment: .leading, spacing: 25) {
            placementPicker
            transmissionTypePicker
            if viewModel.shouldShowCompleteCredentials() {
                wifiNameAndPasswordEntry
            } else if viewModel.isWiFi {
               wifiPasswordEntry
            }
        }
    }
    
    var wifiNameAndPasswordEntry: some View {
        VStack(alignment: .leading, spacing: 25) {
            provideNameAndPasswordTitle
            if #available(iOS 15.0, *) {
               wifiSSIDField
                    .onSubmit { viewModel.isSSIDTextfieldDisplayed = false }
            } else {
                wifiSSIDField
            }
            wifiPasswordField
        }
    }
    
    var wifiPasswordEntry: some View {
        VStack(alignment: .leading, spacing: 15) {
            if viewModel.showWifiPasswordField {
                providePasswordTitle
                wifiPasswordField
            } else {
                connectedWifiLabel
                updatePasswordButton
            }
            connectToDifferentWifi
        }
    }
    
    private var updatePasswordButton: some View {
        Button(Strings.WifiPopupView.updatePassword) {
            viewModel.updatePasswordTapped()
        }
    }
    
    var wifiPasswordField: some View {
        createTextfield(placeholder: Strings.WifiPopupView.passwordPlaceholder, binding: $viewModel.wifiPassword)
            .font(Fonts.moderateRegularHeading2)
    }
    
    var wifiSSIDField: some View {
        createTextfield(placeholder: Strings.WifiPopupView.wifiPlaceholder, binding: $viewModel.wifiSSID)
            .font(Fonts.moderateRegularHeading2)
    }
    
    var sessionNameField: some View {
        createTextfield(placeholder: Strings.CreateSessionDetailsView.sessionNamePlaceholder, binding: $viewModel.sessionName)
            .font(Fonts.moderateRegularHeading2)
    }
    
    var sessionTagsField: some View {
        createTextfield(placeholder: Strings.CreateSessionDetailsView.sessionTagPlaceholder, binding: $viewModel.sessionTags)
            .font(Fonts.moderateRegularHeading2)
    }
    
    var navigation: some View {
        ZStack {
            locationPickerLink
            createSesssionLink
            locationLink
        }
    }
    
    var locationPickerLink: some View {
        NavigationLink(
            destination: ChooseCustomLocationView(creatingSessionFlowContinues: $creatingSessionFlowContinues, sessionName: viewModel.sessionName),
            isActive: $viewModel.isLocationSessionDetailsActive,
            label: {
                EmptyView()
            }
        )
    }
    
    var locationLink: some View {
        NavigationLink(
            destination: TurnOnLocationFixedView(creatingSessionFlowContinues:  $creatingSessionFlowContinues,
                                                 viewModel: .init(sessionContext: sessionContext)),
            isActive: $viewModel.isLocationScreenNedeed,
            label: {
                EmptyView()
            }
        )
    }
    
    var createSesssionLink: some View {
        NavigationLink(
            destination: WiFiCheckView(wifiSSID: viewModel.wifiSSID, wifiPassword: viewModel.wifiPassword),
            isActive: $viewModel.isConfirmCreatingSessionActive,
            label: {
                EmptyView()
            }
        )
    }
    
    
    var continueButton: some View {
        Button(action: {
            let updatedContext = viewModel.onContinueClick(sessionContext: sessionContext)
            sessionContext.ovverride(sessionContext: updatedContext)
        }, label: {
            Text(Strings.Commons.continue)
                .font(Fonts.muliBoldHeading1)
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(BlueButtonStyle())
        .disabled(sessionContext.sessionType == .fixed && viewModel.areCredentialsEmpty())
    }

    var titleLabel: some View {
        Text(Strings.CreateSessionDetailsView.title)
            .font(Fonts.muliHeavyTitle1)
            .foregroundColor(.darkBlue)
    }

    var placementPicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.CreateSessionDetailsView.placementPicker_1)
                .font(Fonts.moderateBoldHeading1)
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
                .font(Fonts.moderateBoldHeading1)
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $viewModel.isWiFi, label: Text("")) {
                Text(Strings.CreateSessionDetailsView.wifiText).tag(true)
                Text(Strings.CreateSessionDetailsView.cellularText).tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    var providePasswordTitle: some View {
        Text(String(format: Strings.WifiPopupView.passwordTitle, arguments: [viewModel.wifiSSID]))
            .font(Fonts.muliBoldHeading1)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var provideNameAndPasswordTitle: some View {
        Text(Strings.WifiPopupView.nameAndPasswordTitle)
            .font(Fonts.muliBoldHeading1)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var connectedWifiLabel: some View {
        Text(String(format: Strings.WifiPopupView.connectedNetworkTitle, arguments: [viewModel.wifiSSID]))
            .font(Fonts.muliBoldHeading1)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var connectToDifferentWifi: some View {
        Button(Strings.WifiPopupView.differentNetwork) {
            viewModel.connectToOtherNetworkClick()
        }
    }
}

