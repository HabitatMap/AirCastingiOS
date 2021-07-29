// Created by Lunar on 29/07/2021.
//

import Foundation

class SessionCartViewModel: ObservableObject {
    private let sessionCartFollowing: SessionCartFollowing
    
    init(sessionCartFollowing: SessionCartFollowing) {
        self.sessionCartFollowing = sessionCartFollowing
    }
    
    func toggleFollowing(for session: SessionEntity) {
        session.followedAt != nil ? sessionCartFollowing.makeFollowing(for: session) : sessionCartFollowing.makeNotFollowing(for: session)
    }
}

class DefaultSessionCartFollowing: SessionCartFollowing {
    private let measurementStreamStorage: MeasurementStreamStorage
    
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
