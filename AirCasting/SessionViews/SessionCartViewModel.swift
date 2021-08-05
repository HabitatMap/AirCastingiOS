// Created by Lunar on 29/07/2021.
//

import Foundation

class SessionCartViewModel: ObservableObject {
    private let sessionCartFollowing: SessionCartFollowing
    @Published var isFollowing: Bool = false
    
    init(sessionCartFollowing: SessionCartFollowing) {
        self.sessionCartFollowing = sessionCartFollowing
    }
    
    func toggleFollowing(for session: SessionEntity) {
        session.followedAt != nil ? sessionCartFollowing.makeFollowing(for: session) : sessionCartFollowing.makeNotFollowing(for: session)
        switch determineCurrentState(for: session) {
            case true: isFollowing = true
            case false: isFollowing = false
        }
    }
    
    private func determineCurrentState(for session: SessionEntity) -> Bool {
        if session.followedAt == nil && session.type == .fixed {
            return false
        } else if session.followedAt != nil {
            return true
        } else {
            return false
        }
    }
}

class DefaultSessionCartFollowing: SessionCartFollowing {
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func makeFollowing(for session: SessionEntity) {
        try? measurementStreamStorage.updateSessionFollowing(SessionFollowing.following, for: session.uuid)
    }
    
    func makeNotFollowing(for session: SessionEntity) {
        try? measurementStreamStorage.updateSessionFollowing(SessionFollowing.notFollowing, for: session.uuid)
    }
}
