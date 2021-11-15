// Created by Lunar on 15/11/2021.
//

import SwiftUI

func finishSessionAlert(sessionStopper: SessionStoppable, sessionName: String?) -> Alert {
    Alert(title: Text(Strings.SessionHeaderView.finishAlertTitle) +
            Text(sessionName ?? Strings.SessionHeaderView.finishAlertTitle_2)
            +
            Text(Strings.SessionHeaderView.finishAlertTitle_3),
          message: Text(Strings.SessionHeaderView.finishAlertMessage_1) +
            Text(Strings.SessionHeaderView.finishAlertMessage_2) +
            Text(Strings.SessionHeaderView.finishAlertMessage_3),
          primaryButton: .default(Text(Strings.SessionHeaderView.finishAlertButton), action: {
            do {
                try sessionStopper.stopSession()
            } catch {
                Log.info("error when stpoing session - \(error)")
            }
          }),
          secondaryButton: .cancel())
}
