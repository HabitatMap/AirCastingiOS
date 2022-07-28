// Created by Lunar on 28/07/2022.
//

import Foundation
import Resolver

protocol SettingsController {
    func changeDormantAlertSettings(to value: Bool)
}

struct DefaultSettingsController: SettingsController {
    private var apiConntector = DormantStreamAlertAPI()
    
    func changeDormantAlertSettings(to value: Bool) {
        apiConntector.sendNewSetting(value: value) { result in
            switch result {
            case .success():
                Log.debug("## SUCCESS")
            case .failure(let error):
                Log.error("\(error)")
            }
        }
    }
}
