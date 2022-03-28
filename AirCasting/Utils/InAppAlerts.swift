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
    static func notSupportedBTAlert() -> AlertInfo {
        AlertInfo(title: Strings.DeviceHandler.alertTitle,
                  message: Strings.DeviceHandler.alertMessage,
                  buttons: [
                    .default(title: Strings.Commons.continue,
                             action: nil)
                  ])
    }
    
    static func noNetworkAlert(dismiss: (() -> Void)? = nil) -> AlertInfo {
        AlertInfo(title: Strings.NetworkAlert.alertTitle,
                  message: Strings.NetworkAlert.alertMessage,
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
    
    static func failedEmailSharingAlert() -> AlertInfo {
        AlertInfo(title: Strings.SessionShare.emailSharingAlertTitle,
                  message: Strings.SessionShare.emailSharingAlertMessage,
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
    
    static func connectionTimeoutAlert(dismiss: ()) -> AlertInfo {
        AlertInfo(title: Strings.AirBeamConnector.connectionTimeoutTitle,
                  message: Strings.AirBeamConnector.connectionTimeoutDescription,
                  buttons: [ .default(title: Strings.Commons.gotIt,
                                      action: { dismiss }) ])
    }
    
    static func failedSDClearingAlert(dismiss: ()) -> AlertInfo {
        AlertInfo(title: Strings.ClearingSDCardView.failedClearingAlertTitle,
                  message: Strings.ClearingSDCardView.failedClearingAlertMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: { dismiss }) ])
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
    
    static func locationAlert() -> AlertInfo {
        let redirection = Resolver.resolve(SettingsRedirection.self)
        return AlertInfo(title: Strings.SelectDeviceView.alertTitle,
                         message: Strings.SelectDeviceView.alertMessage,
                         buttons: [
                            .cancel(title: Strings.Commons.ok),
                            .default(title: Strings.SelectDeviceView.alertSettings,
                                     action: redirection.goToLocationAuthSettings)])
    }
    
    static func unableToLogOutAlert() -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.unableToLogOutTitle,
                  message: Strings.InAppAlerts.unableToLogOutMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.unableToLogOutButton,
                             action: nil)
                  ])
    }
    
    static func downloadingSessionsFailedAlert(action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedTitle,
                  message: Strings.InAppAlerts.downloadingFailedMessage,
                  buttons: [
                    .default(title: Strings.Commons.gotIt,
                             action: action)
                    ])
                }
                    
    static func failedToDownload(dismiss: ()) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedDownloadTitle,
                  message: Strings.InAppAlerts.failedDownloadMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.failedDownloadButton,
                             action: { dismiss })
                  ])
    }
    
    static func failedSavingData(dismiss: ()) -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.failedSavingTitle,
                  message: Strings.InAppAlerts.failedSavingMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.failedSavingButton,
                             action: { dismiss })
                  ])
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
