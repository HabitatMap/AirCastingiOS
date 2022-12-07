// Created by Lunar on 07/12/2022.
//

import Foundation
@testable import AirCasting

class MobileSessionFinishingStorageMock: MobileSessionFinishingStorage {
    let hiddenStorage = HiddenStorage()
    func accessStorage(_ task: @escaping (AirCasting.HiddenMobileSessionFinishingStorage) -> Void) {
        task(hiddenStorage)
    }

    class HiddenStorage: HiddenMobileSessionFinishingStorage {
        var callHistory: [SessionStatus] = []
        func save() throws {}
        func updateSessionStatus(_ sessionStatus: AirCasting.SessionStatus, for sessionUUID: AirCasting.SessionUUID) throws {
            callHistory.append(sessionStatus)
        }
        func updateSessionEndtime(_ endTime: Date, for sessionUUID: AirCasting.SessionUUID) throws { }
    }
}
