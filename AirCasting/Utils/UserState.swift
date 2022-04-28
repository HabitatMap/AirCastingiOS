// Created by Lunar on 05/11/2021.
//

import Foundation

class UserState: ObservableObject {
    enum State {
        /// Set while the user is in the process of logging out
        case loggingOut
        /// Set while the user is in the process of account deletion
        case deletingAccount
        /// Set when the user is logged in or logged out
        case idle
    }
    
    @Published var currentState: State = .idle
}
