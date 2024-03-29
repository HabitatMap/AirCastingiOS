// Created by Lunar on 28/07/2022.
//

import Foundation
import Resolver

protocol SettingsController {
    func changeDormantAlertSettings(to value: Bool, completion: @escaping (Result<Void, Error>) -> Void)
}

struct DefaultSettingsController: SettingsController {
    @Injected private var apiConnector: DormantStreamAlertService
    
    func changeDormantAlertSettings(to value: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        apiConnector.sendNewSetting(value: value) { result in
            switch result {
            case .success():
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
