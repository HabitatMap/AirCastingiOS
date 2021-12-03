// Created by Lunar on 29/07/2021.
//

import Foundation

class SessionCardViewModel: ObservableObject {
    private var followingSetter: SessionFollowingSettable
    @Published var isFollowing: Bool
    
    init(followingSetter: SessionFollowingSettable) {
        self.followingSetter = followingSetter
        self.isFollowing = (followingSetter.following == .following)
    }
    
    func toggleFollowing() {
        followingSetter.following = followingSetter.following.toggled()
        updateFollowingState()
    }
    
    private func updateFollowingState() {
        switch followingSetter.following {
        case .following: isFollowing = true
        case .notFollowing: isFollowing = false
        }
    }
}
