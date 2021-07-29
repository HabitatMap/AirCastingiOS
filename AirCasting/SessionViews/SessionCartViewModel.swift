// Created by Lunar on 29/07/2021.
//

import Foundation

class SessionCartViewModel: ObservableObject, SessionCartFollowing {

    var measurementStreamStorage: MeasurementStreamStorage
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func makeFollowing(for session: SessionEntity) {
        try? measurementStreamStorage.updateSessionIfFollowing(SessionFollowing.following, for: session.uuid)
    }
    func makeNotFollowing(for session: SessionEntity) {
        try? measurementStreamStorage.updateSessionIfFollowing(SessionFollowing.notFollowing, for: session.uuid)
    }
}
