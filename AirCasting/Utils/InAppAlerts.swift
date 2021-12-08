// Created by Lunar on 01/12/2021.
//

import Foundation
// This struct provides all nedded alerts in case of need. Using them from here, allows you
// to place multiple instances of them (in one view) and every one of them will be called and show up nicely.
// Key thing here - is the id.
// Use them, have fun, ALERT the user 🛎
struct AlertInfo: Identifiable {
    enum Button {
        case cancel
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
                    .default(title: Strings.DeviceHandler.continueText, action: nil)
                  ])
    }
    
    static func noNetworkAlert() -> AlertInfo {
        AlertInfo(title: Strings.NetworkAlert.alertTitle,
                  message: Strings.NetworkAlert.alertMessage,
                  buttons: [
                    .default(title: Strings.NetworkAlert.confirmAlert, action: nil)
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
                .default(title: Strings.SessionHeaderView.finishAlertButton, action: action),
                .cancel
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
                .default(title: Strings.SessionHeaderView.finishAlertButton, action: action),
                .cancel
            ]
        )
    }
}

import SwiftUI

extension AlertInfo {
    func makeAlert() -> Alert {
        assert(buttons.count >= 1 && buttons.count <= 2, "Unsupported button count! For SwiftUI implementation max of 2 buttons is supported")
        
        let alertButtons = buttons.map { type -> Alert.Button in
            switch type {
            case .cancel: return Alert.Button.cancel()
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
