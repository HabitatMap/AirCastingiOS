// Created by Lunar on 15/10/2021.
//

import Foundation
import SwiftUI

struct Fonts {
    enum ForgotPasswordView {
        static let title: Font = Font.moderate(size: 32, weight: .bold)
    }
    
    enum MainTabBarView {
        static let title: Font = Font(UIFont.systemFont(ofSize: 24, weight: .bold))
    }
    
    enum GetStarted {
        static let description: Font = Font.muli(size: 16)
    }
    
    enum NearAirDescription {
        static let title: Font = Font.moderate(size: 32, weight: .bold)
        static let description: Font = Font.muli(size: 16)
        static let continueButton: Font = Font.moderate(size: 16, weight: .semibold)
    }
    
    enum AirBeamOnboarding {
        static let title: Font = Font.moderate(size: 28, weight: .bold)
        static let description: Font = Font.muli(size: 16)
        static let titleText: Font = Font.moderate(size: 32, weight: .bold)
        static let button: Font = Font.moderate(size: 16, weight: .semibold)
    }
    
    enum PrivacyOnboarding {
        static let sheetTitle: Font = Font.moderate(size: 28, weight: .bold)
        static let sheetDescription: Font = Font.muli(size: 14)
        static let title: Font = Font.moderate(size: 32, weight: .bold)
        static let description: Font = Font.muli(size: 16)
        static let continueButton: Font = Font.moderate(size: 16, weight: .semibold)
    }
    
    enum EmptyMobileDashboard {
        static let emptyTextOne: Font = Font.moderate(size: 24, weight: .bold)
        static let emptyTextTwo: Font = Font.muli(size: 16)
        static let descriptionOne: Font = Font.muli(size: 16, weight: .semibold)
        static let descriptionTwo: Font = Font.muli(size: 14)
    }
    
    enum EmptyFixedDashboard {
        static let emptyTextOne: Font = Font.moderate(size: 24, weight: .bold)
        static let emptyTextTwo: Font = Font.muli(size: 16)
    }
    
    enum AirSectionPickerView {
        static let isSelected: Font = Font.muli(size: 16, weight: .bold)
        static let isNotSelected: Font = Font.muli(size: 16, weight: .regular)
    }
    
    enum CreateAccountView {
        static let titleOne: Font = Font.moderate(size: 32, weight: .bold)
        static let titleTwo: Font = Font.muli(size: 16)
        static let signingOne: Font = Font.muli(size: 16)
        static let signingTwo: Font = Font.moderate(size: 16, weight: .bold)
    }
    
    enum SignInView {
        static let titleOne: Font = Font.moderate(size: 32, weight: .bold)
        static let titleTwo: Font = Font.muli(size: 16)
        static let signupOne: Font = Font.muli(size: 16)
        static let signupTwo: Font = Font.moderate(size: 16, weight: .bold)
    }
    
    enum AuthErrorHandling {
        static let error: Font = Font.moderate(size: 10)
    }
    
    enum SettingView {
        static let signOut: Font = Font.muli(size: 16, weight: .bold)
        static let crowdMapTitle: Font = Font.muli(size: 16, weight: .bold)
        static let crowdMapDescription: Font = Font.muli(size: 16, weight: .regular)
        static let navigateToBackendButton: Font = Font.muli(size: 16, weight: .regular)
    }
    
    enum BackendSettingsView {
        static let title: Font = Font.muli(size: 24, weight: .semibold)
    }
    
    enum MyAccountSignOut {
        static let logInLabel: Font = Font.muli(size: 16)
    }
    
    enum ChooseSessionTypeView {
        static let title: Font = Font.moderate(size: 32, weight: .bold)
        static let messageLabel: Font = Font.moderate(size: 18, weight: .regular)
        static let recordNewLabel: Font = Font.muli(size: 14, weight: .bold)
        static let moreInfo: Font = Font.moderate(size: 14)
        static let fixedOneLabel: Font = Font.muli(size: 16, weight: .bold)
        static let fixedTwoLabel: Font = Font.muli(size: 14, weight: .regular)
        static let mobileOneLabel: Font = Font.muli(size: 16, weight: .bold)
        static let mobileTwoLabel: Font = Font.muli(size: 14, weight: .regular)
    }
    
    enum TurnOnLocationView {
        static let titleLabel: Font = Font.moderate(size: 25, weight: .bold)
        static let messageLabel: Font = Font.moderate(size: 18, weight: .regular)
    }
    
    enum MoreInfoPopupView {
        static let first: Font = Font.moderate(size: 28, weight: .bold)
        static let second: Font = Font.muli(size: 16)
    }
    
    enum SelectDeviceView {
        static let title: Font = Font.moderate(size: 25, weight: .bold)
        static let bluetoothOneLabel: Font = Font.muli(size: 16, weight: .bold)
        static let bluetoothTwoLabel: Font = Font.muli(size: 14, weight: .regular)
        static let micOneLabel: Font = Font.muli(size: 16, weight: .bold)
        static let micTwoLabel: Font = Font.muli(size: 14, weight: .regular)
    }
    
    enum TurnOnBluetoothView {
        static let title: Font = Font.moderate(size: 25, weight: .bold)
        static let message: Font = Font.moderate(size: 18, weight: .regular)
    }
    
    enum PowerABView {
        static let title: Font = Font.moderate(size: 25, weight: .bold)
        static let message: Font = Font.moderate(size: 18, weight: .regular)
    }
    
    enum SelectPerehicalView {
        static let VFont: Font = Font.moderate(size: 18, weight: .regular)
        static let title: Font = Font.moderate(size: 25, weight: .bold)
        static let showDevice: Font = Font.muli(size: 16, weight: .medium)
    }
    
    enum ConnectingABView {
        static let title: Font = Font.moderate(size: 25, weight: .bold)
        static let message: Font = Font.moderate(size: 18, weight: .regular)
    }
    
    enum ABConnectedView {
        static let title: Font = Font.moderate(size: 25, weight: .bold)
        static let message: Font = Font.moderate(size: 18, weight: .regular)
    }
    
    enum CreateSessionDetailedView {
        static let title: Font = Font.moderate(size: 24, weight: .bold)
        static let placementPicker: Font = Font.moderate(size: 16, weight: .bold)
        static let transmissionPicker: Font = Font.moderate(size: 16, weight: .bold)
    }
    
    enum ChooseCustomLocation {
        static let title: Font = Font.moderate(size: 24, weight: .bold)
    }
    
    enum WiFiPopupView {
        static let title: Font = Font.muli(size: 18, weight: .heavy)
    }
    
    enum ConfrimCreatingSessionView {
        static let title: Font = Font.moderate(size: 24, weight: .bold)
        static let sessionType: Font = Font.muli(size: 16)
    }
    
    enum SessionCartView {
        static let sessionCard: Font = Font.moderate(size: 13, weight: .regular)
        static let graphButton: Font = Font.muli(size: 13, weight: .semibold)
        static let groupFont: Font = Font.muli(size: 13, weight: .semibold)
        static let mapButton: Font = Font.muli(size: 13, weight: .semibold)
    }
    
    enum SessionHeaderView {
        static let vStackFont: Font = Font.moderate(size: 13, weight: .regular)
        static let sessionName: Font = Font.moderate(size: 18, weight: .regular)
        static let sensorType: Font = Font.moderate(size: 13, weight: .regular)
    }
    
    enum DeleteView {
        static let title: Font = Font.moderate(size: 24, weight: .bold)
        static let description: Font = Font.muli(size: 16)
    }
    
    enum ShareView {
        static let title: Font = Font.moderate(size: 32, weight: .bold)
        static let description: Font = Font.muli(size: 16)
        static let descriptionMail: Font = Font.muli(size: 12)
    }
    
    enum SessionLoadingView {
        static let vStackFont: Font = Font.moderate(size: 13)
    }
    
    enum ABMeasurementsView {
        static let title: Font = Font.moderate(size: 12)
        static let measurementTitle: Font = Font.moderate(size: 12)
    }
    
    enum SingleMeasurementView {
        static let stremName: Font = Font.system(size: 13)
        static let value: Font = Font.moderate(size: 14, weight: .regular)
    }
    
    enum HeatmapSettingsView {
        static let heatmapTitle: Font = Font.muli(size: 24, weight: .heavy)
        static let heatmapDescription: Font = Font.moderate(size: 16, weight: .regular)
        static let showDescription: Font = Font.muli(size: 13)
        static let showThreshold: Font = Font.muli(size: 14)
    }
    
    enum MultiSliderView {
        static let labels: Font = Font.muli(size: 12)
        static let value: Font = Font.moderate(size: 14, weight: .regular)
    }
    
    enum StatisticsContainerView {
        static let body: Font = Font.muli(size: 12)
        static let value: Font = Font.muli(size: 12)
        static let parameterValue: Font = Font.muli(size: 19)
    }
    
    enum EditModalView {
        static let title: Font = Font.moderate(size: 24, weight: .bold)
        static let continueButton: Font = Font.moderate(size: 16, weight: .semibold)
    }
    
    enum GraphRenderers {
        static let upperLabel: UIFont = UIFont.muli(size: 14)
        static let bottomLabel: UIFont = UIFont.muli(size: 14)
    }
}
