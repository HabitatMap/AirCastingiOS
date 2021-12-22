// Created by Lunar on 01/12/2021.
//

import Foundation
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
                    .default(title: Strings.DeviceHandler.continueText,
                             action: nil)
                  ])
    }
    
    static func noNetworkAlert() -> AlertInfo {
        AlertInfo(title: Strings.NetworkAlert.alertTitle,
                  message: Strings.NetworkAlert.alertMessage,
                  buttons: [
                    .default(title: Strings.NetworkAlert.confirmAlert,
                             action: nil)
                  ])
    }
    
    static func finishSessionAlert(sessionName: String?, action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.SessionHeaderView.finishAlertTitle +
            (sessionName ?? Strings.SessionHeaderView.finishAlertTitle_2) +
            (Strings.SessionHeaderView.finishAlertTitle_3),
            message: Strings.SessionHeaderView.finishAlertMessage_1 +
            (Strings.SessionHeaderView.finishAlertMessage_2) +
            (Strings.SessionHeaderView.finishAlertMessage_3),
            buttons: [
                .default(title: Strings.SessionHeaderView.finishAlertButton,
                         action: action),
                .cancel()
            ]
        )
    }
    
    static func finishAndSyncAlert(sessionName: String?, action: @escaping (() -> Void)) -> AlertInfo {
        AlertInfo(
            title: Strings.SessionHeaderView.finishAlertTitle +
            (sessionName ?? Strings.SessionHeaderView.finishAlertTitle_2) +
            Strings.SessionHeaderView.finishAlertTitle_3_SYNC,
            message: Strings.SessionHeaderView.finishAlertMessage_1 +
            Strings.SessionHeaderView.finishAlertMessage_2 +
            Strings.SessionHeaderView.finishAlertMessage_3 +
            Strings.SessionHeaderView.finishAlertMessage_4,
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
                  buttons: [ .default(title: Strings.AirBeamConnector.connectionTimeoutActionTitle,
                                      action: { dismiss }) ])
    }
    
    static func failedSDClearingAlert(dismiss: ()) -> AlertInfo {
        AlertInfo(title: Strings.ClearingSDCardView.failedClearingAlertTitle,
                  message: Strings.ClearingSDCardView.failedClearingAlertMessage,
                  buttons: [
                    .default(title: Strings.AirBeamConnector.connectionTimeoutActionTitle,
                             action: { dismiss }) ])
    }
    
    static func microphonePermissionAlert() -> AlertInfo {
        AlertInfo(title: Strings.MicrophoneAlert.title,
                  message: Strings.MicrophoneAlert.message,
                  buttons: [
                    .cancel(title: Strings.SelectDeviceView.alertConfirmation),
                    .default(title: Strings.SelectDeviceView.alertSettings,
                             action: SettingsManager.goToAuthSettings)])
    }
    
    static func locationAlert() -> AlertInfo {
        AlertInfo(title: Strings.SelectDeviceView.alertTitle,
                  message: Strings.SelectDeviceView.alertMessage,
                  buttons: [
                    .cancel(title: Strings.SelectDeviceView.alertConfirmation),
                    .default(title: Strings.SelectDeviceView.alertSettings,
                             action: DefaultSettingsRedirection().goToLocationAuthSettings)])
    }
    
    static func unableToLogOutAlert() -> AlertInfo {
        AlertInfo(title: Strings.InAppAlerts.unableToLogOutTitle,
                  message: Strings.InAppAlerts.unableToLogOutMessage,
                  buttons: [
                    .default(title: Strings.InAppAlerts.unableToLogOutButton,
                             action: nil)
                  ])
    }
}

import SwiftUI

extension AlertInfo {
    func makeAlert() -> Alert {
        assert(buttons.count >= 1 && buttons.count <= 2, Strings.InAppAlerts.assertError)
        
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
