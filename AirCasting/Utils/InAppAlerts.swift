// Created by Lunar on 01/12/2021.
//

import SwiftUI
// This struct provides all nedded alerts in case of need. Using them from here, allows you
// to place multiple instances of them (in one view) and every one of them will be called and show up nicely.
// Key thing here - is the id.
// Use them, have fun, ALERT the user 🛎
struct AlertInfo: Identifiable {
    enum AlertType {
        case finishSessionAlert
        case finishSessionAndSyncAlert
        case BTAlert
        case noNetworkAlert
    }
    
    let id: AlertType
    let title: Text
    let message: Text
    let buttonTitle: Text
}

struct InAppAlerts {
    static func notSupportedBTAlert() -> AlertInfo {
        AlertInfo(id: .BTAlert,
                  title: Text(Strings.DeviceHandler.alertTitle),
                  message: Text(Strings.DeviceHandler.alertMessage),
                  buttonTitle: Text(Strings.DeviceHandler.continueText))
    }
    
    static func noNetworkAlert() -> AlertInfo {
        AlertInfo(id: .noNetworkAlert,
                  title: Text(Strings.NetworkAlert.alertTitle),
                  message: Text(Strings.NetworkAlert.alertMessage),
                  buttonTitle: Text(Strings.NetworkAlert.confirmAlert))
    }
    
    static func finishSessionAlert(sessionName: String?) -> AlertInfo {
        AlertInfo(id: .finishSessionAlert,
                  title: Text((Strings.SessionHeaderView.finishAlertTitle) +
                              (sessionName ?? Strings.SessionHeaderView.finishAlertTitle_2) +
                              (Strings.SessionHeaderView.finishAlertTitle_3)),
                  message: Text((Strings.SessionHeaderView.finishAlertMessage_1) +
                                (Strings.SessionHeaderView.finishAlertMessage_2) +
                                (Strings.SessionHeaderView.finishAlertMessage_3)),
                  buttonTitle: Text(Strings.SessionHeaderView.finishAlertButton))
    }
    
    static func finishAndSyncAlert(sessionName: String?) -> AlertInfo {
        AlertInfo(id: .finishSessionAndSyncAlert,
                  title: Text(Strings.SessionHeaderView.finishAlertTitle +
                              (sessionName ?? Strings.SessionHeaderView.finishAlertTitle_2) +
                              Strings.SessionHeaderView.finishAlertTitle_3_SYNC),
                  message: Text(Strings.SessionHeaderView.finishAlertMessage_1 +
                                Strings.SessionHeaderView.finishAlertMessage_2 +
                                Strings.SessionHeaderView.finishAlertMessage_3 +
                                Strings.SessionHeaderView.finishAlertMessage_4),
                  buttonTitle: Text(Strings.SessionHeaderView.finishAlertButton))
    }
}
