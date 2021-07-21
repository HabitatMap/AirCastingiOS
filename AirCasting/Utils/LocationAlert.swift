// Created by Lunar on 21/07/2021.
//

import SwiftUI

var locationAlert: Alert {
    Alert(
        title: Text(Strings.SelectDeviceView.alertTitle),
        message: Text(Strings.SelectDeviceView.alertMessage),
        primaryButton: .cancel(Text(Strings.SelectDeviceView.alertConfirmation)) { },
        secondaryButton: .default(Text(Strings.SelectDeviceView.alertSettings), action: {
            goToLocationAuthSettings()
        })
    )
}
