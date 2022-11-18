// Created by Lunar on 01/12/2021.
//

import Foundation
import Resolver

// This struct provides all nedded alerts in case of need. Using them from here, allows you
// to place multiple instances of them (in one view) and every one of them will be called and show up nicely.
// Key thing here - is the id.
// Use them, have fun, ALERT the user 🛎
struct AlertInfo: Identifiable {
    enum Button {
        case cancel(title: String = "Cancel")
        case `default`(title: String, action: (() -> Void)?)
    }
    
    var id: String { title + message }
    let title: String
    let message: String
    let buttons: [Button]
}

struct InAppAlerts {
    static func noNetworkAlert(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.NetworkAlert.alertTitle,
                  message: Strings.NetworkAlert.alertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func noNetworkSyncAlert(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.noInternetConnectionTitle,
                  message: Strings.InAppAlerts.noInternetConnectionSyncMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func noNetworkEditAlert(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.noInternetConnectionTitle,
                  message: Strings.InAppAlerts.noInternetConnectionEditMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func noWifiNetworkSyncAlert(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.noWifiConnectionTitle,
                  message: Strings.InAppAlerts.noWifiConnectionSyncMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func noNetworkAuthorizationAlert(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.NetworkAlert.alertTitle,
                  message: Strings.NetworkAuthorizationAlert.alertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func noInternetConnectionSignOutAlert() -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.noInternetConnectionTitle,
                  message: Strings.InAppAlerts.noInternetConnectionSignOutMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.noInternetConnectionButton,
                             action: nil)
                  ])
    }
    
    static func backendSettingsLogoutAlert() -> AlertInfo {
        AlertInfo(title: Strings.BackendSettings.alertTitle,
                  message: Strings.BackendSettings.alertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: nil)
                  ])
    }
    
    static func failedThresholdAlertsAlert(dismiss: @escaping () -> Void) -> AlertInfo {
        AlertInfo(title: Strings.ThresholdAlertSheet.failureAlertTitle,
                  message: Strings.ThresholdAlertSheet.failureAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func failedThresholdAlertsFetchingAlert(dismiss: @escaping () -> Void) -> AlertInfo {
        AlertInfo(title: Strings.ThresholdAlertSheet.failureAlertTitle,
                  message: Strings.ThresholdAlertSheet.fetchingFailureAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss)
                  ])
    }
    
    static func failedSharingAlert() -> AlertInfo {
        AlertInfo(title: Strings.SessionShare.linkSharingAlertTitle,
                  message: Strings.SessionShare.linkSharingAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: nil)
                  ])
    }
    
    static func shareFileRequestSent() -> AlertInfo {
        AlertInfo(
            title: Strings.SessionHeaderView.shareFileAlertTitle,
            message: Strings.SessionHeaderView.shareFileAlertMessage,
            buttons: [
                .default(title: Strings.Commons.gotIt,
                         action: nil)
            ]
        )
    }
    
    static func failedDormantStreamSettingAlert() -> AlertInfo {
        AlertInfo(title: Strings.Settings.failedDormantStreamAlertTitle,
                  message: Strings.Settings.failedDormantStreamAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: nil)
                  ])
    }
    
    static func finishSessionAlert(sessionName: String?, action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: ((sessionName == nil) ? Strings.SessionHeaderView.finishAlertTitleNoName : String(format: Strings.SessionHeaderView.finishAlertTitleNamed, arguments: [sessionName!])),
            message: Strings.SessionHeaderView.finishAlertMessage,
            buttons: [
                .default(title: Strings.SessionHeaderView.finishAlertButton,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func failedFinishingSession() -> AlertInfo {
        AlertInfo(
            title: Strings.SessionHeaderView.failedFinishSessionTitle,
            message: Strings.SessionHeaderView.failedFinishSessionMessage,
            buttons: [.default(title: Strings.Commons.gotIt,
                         action: nil)]
        )
    }
    
    static func cannotReconnectSession(sessionName: String?) -> AlertInfo {
        AlertInfo(
            title: Strings.SessionHeaderView.cannotReconnectAlertTitle,
            message: Strings.SessionHeaderView.cannotReconnectAlertMessage,
            buttons: [.default(title: Strings.Commons.gotIt,
                         action: nil)]
        )
    }
    
    static func finishAndSyncAlert(sessionName: String?, action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: ((sessionName == nil) ? Strings.SessionHeaderView.finishAlertTitleSYNCNoName : String(format: Strings.SessionHeaderView.finishAlertTitleNamed, arguments: [sessionName!])),
            message: Strings.SessionHeaderView.finishAlertMessage +
            Strings.SessionHeaderView.finishAlertMessage_withSync,
            buttons: [
                .default(title: Strings.SessionHeaderView.finishAlertButton,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func connectionTimeoutAlert(dismiss: @escaping () -> Void) -> AlertInfo {
        AlertInfo(title: Strings.AirBeamConnector.connectionTimeoutTitle,
                  message: Strings.AirBeamConnector.connectionTimeoutDescription,
                  buttons: [ .default(title: Strings.Commons.gotIt,
                                      action: dismiss) ])
    }
    
    static func microphonePermissionAlert() -> AlertInfo {
        AlertInfo(title: Strings.MicrophoneAlert.title,
                  message: Strings.MicrophoneAlert.message,
                  buttons: [
                    .cancel(title: Strings.Commons.ok),
                    .default(title: Strings.SelectDeviceView.alertSettings,
                             action: SettingsManager.goToAuthSettings)])
    }
    
    static func microphoneSessionAlreadyRecordingAlert() -> AlertInfo {
        AlertInfo(title: Strings.MicrophoneSessionAlreadyRecordingAlert.title,
                  message: Strings.MicrophoneSessionAlreadyRecordingAlert.message,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: nil) ])
    }
    
    static func bluetoothSessionAlreadyRecordingAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.BluetoothSessionAlreadyRecordingAlert.title,
                  message: Strings.BluetoothSessionAlreadyRecordingAlert.message,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func incompatibleDevice(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.IncompatibleDeviceAlert.title,
                  message: Strings.IncompatibleDeviceAlert.message,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func failedAirBeamConfiguration(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.airBeamConfigurationFailureTitle,
                  message: Strings.InAppAlerts.airBeamConfigurationFailureTMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func locationAlert() -> AlertInfo {
        let redirection = Resolver.resolve(SettingsRedirection.self)
        return AlertInfo(title: Strings.SelectDeviceView.alertTitle,
                         message: Strings.SelectDeviceView.alertMessage,
                         buttons: [
                            .cancel(title: Strings.Commons.ok),
                            .default(title: Strings.SelectDeviceView.alertSettings,
                                     action: redirection.goToLocationAuthSettings)])
    }
    
    static func failedSessionDownloadAlert(dismiss: @escaping () -> Void) -> AlertInfo {
        AlertInfo(title: Strings.CompleteSearchView.failedDownloadAlertTitle,
                  message: Strings.CompleteSearchView.failedDownloadAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss ) ])
    }
    
    static func downloadingSessionsFailedAlert(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedTitle,
                  message: Strings.InAppAlerts.downloadingFailedMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: action)
                  ])
    }
    
    static func failedToDownload(dismiss: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedDownloadTitle,
                  message: Strings.InAppAlerts.failedDownloadMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.failedDownloadButton,
                             action: dismiss)
                  ])
    }
    
    static func failedSavingData(dismiss: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedSavingTitle,
                  message: Strings.InAppAlerts.failedSavingMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.failedSavingButton,
                             action: dismiss)
                  ])
    }
    
    static func firstConfirmationDeletingAccountAlert(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.firstDeletingAccountTitle, message: Strings.InAppAlerts.firstDeletingAccountMessage,
            buttons: [
                .default(title: Strings.InAppAlerts.firstConfirmingDeletingButton,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func secondConfirmationDeletingAccountAlert(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.secondDeletingAccountTitle, message: Strings.InAppAlerts.secondDeletingAccountMessage,
            buttons: [
                .default(title: Strings.InAppAlerts.secondConfirmingDeletingButton,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func successfulAccountDeletionConfirmation(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.accountDeletionSuccessTitle, message: Strings.InAppAlerts.accountDeletionSuccessMessage,
            buttons: [
                .default(title: Strings.Commons.gotIt,
                         action: action),
            ]
        )
    }
    
    static func unableToConnectBeforeDeletingAccount() -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.unableToConnectTitle, message: Strings.InAppAlerts.unableToConnectMessage, buttons: [
            .default(title: Strings.Commons.gotIt, action: nil)
        ])
    }
    
    static func failedDeletingAccount() -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedTitle, message: Strings.InAppAlerts.failedDeletingAccountErrorMessage, buttons: [
            .default(title: Strings.Commons.gotIt, action: nil)
        ])
    }
    
    static func noInternetConnection(error: AuthorizationError) -> AlertInfo {
        AlertInfo(title: Strings.CreateAccountView.noInternetTitle, message: error.localizedDescription, buttons: [
            .default(title: Strings.Commons.ok, action: nil)
        ])
    }
    
    static func noInternetConnection(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.ConnectionAlerts.noInternetTitle,
                  message: Strings.ConnectionAlerts.noInternetMessage,
                  buttons: [
                    .default(title: Strings.Commons.ok, action: dismiss)
                  ])
    }
    
    static func createAccountAlert(error: AuthorizationError) -> AlertInfo {
        AlertInfo(title: Strings.CreateAccountView.takenAndOtherTitle, message: error.localizedDescription, buttons: [
            .default(title: Strings.Commons.ok, action: nil)
        ])
    }
    
    
    static func signInAlert(error: AuthorizationError) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.signInErrorTitle, message: error.localizedDescription, buttons: [
            .default(title: Strings.Commons.ok, action: nil)
        ])
    }
    
    static func thresholdsValuesSettingsWarning() -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.thresholdsValuesSettingsTitle, message: Strings.InAppAlerts.thresholdsValuesSettingsMessage,
            buttons: [
                .default(title: Strings.Commons.gotIt,
                         action: nil),
            ]
        )
    }
    
    static func logoutWarningAlert(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.logoutWarningTitle, message: Strings.InAppAlerts.logoutWarningMessage,
            buttons: [
                .default(title: Strings.InAppAlerts.logoutWarningConfirmButton,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func genericErrorAlert(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.genericErrorAlertTitle, message: Strings.InAppAlerts.genericErrorAlertMessage,
            buttons: [
                .default(title: Strings.Commons.gotIt,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func failedFetchingLocationlessSessionsAlert() -> AlertInfo {
        AlertInfo(
            title: Strings.InAppAlerts.failedTitle, message: Strings.InAppAlerts.fetchingDataFailedMessage,
            buttons: [
                .default(title: Strings.Commons.ok, action: nil)
            ])
    }
    
    // MARK: - SD Sync
    static func failedSDClearingBasicAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.ClearingSDCardView.failedClearingAlertTitle,
                  message: Strings.ClearingSDCardView.failedClearingAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func failedSDClearingAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.SDSyncAlerts.clearFailTitle,
                  message: Strings.SDSyncAlerts.clearFailMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func sdSyncUnidentifiableDeviceAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.SDSyncAlerts.genericFailTitle,
                  message: Strings.SDSyncAlerts.unidetifiableDeviceMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func sdSyncFilesCorruptedAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.SDSyncAlerts.genericFailTitle,
                  message: Strings.SDSyncAlerts.readingFilesFailMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func sdSyncReadingDataAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.SDSyncAlerts.genericFailTitle,
                  message: Strings.SDSyncAlerts.readingDataFailMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    
    static func sdSyncFixedFailAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.SDSyncAlerts.genericFailTitle,
                  message: Strings.SDSyncAlerts.processingFixedFailMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
    static func sdSyncMobileFailAlert(dismiss: (@escaping () -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.SDSyncAlerts.genericFailTitle,
                  message: Strings.SDSyncAlerts.processingMobileFailMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: dismiss) ])
    }
}

import SwiftUI

extension AlertInfo {
    func makeAlert() -> Alert {
        assert(buttons.count >= 1 && buttons.count <= 2, "Unsupported button count! For SwiftUI implementation max of 2 buttons is supported")
        
        let alertButtons = buttons.map { type -> Alert.Button in
            switch type {
            case .cancel(let title): return Alert.Button.cancel(Text(title))
            case .default(let title, nil): return Alert.Button.default(Text(title))
            case .default(let title, let action): return Alert.Button.default(Text(title), action: action)
            }
        }
        
        if buttons.count == 1 {
            return Alert(title: Text(self.title), message: Text(self.message), dismissButton: alertButtons[0])
        } else {
            return Alert(title: Text(self.title), message: Text(self.message), primaryButton: alertButtons[0], secondaryButton: alertButtons[1])
        }
    }
}
