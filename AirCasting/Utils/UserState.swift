// Created by Lunar on 05/11/2021.
//

import Foundation

class UserState: ObservableObject {
    enum State {
        case loggingOut
        case deletingAccount
        case other
    }
    
    @Published var isShowingLoading = false
    @Published var currentState: State = .loggingOut
}
