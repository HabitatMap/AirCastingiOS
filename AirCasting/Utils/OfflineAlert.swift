// Created by Lunar on 26/07/2021.
//

import SwiftUI

extension Alert {
    static var offlineAlert: Alert {
        Alert(title: Text(Strings.OfflineAlert.title),
              message: Text(Strings.OfflineAlert.message),
              dismissButton: .default(Text(Strings.OfflineAlert.dismissTitle)))
    }
}

