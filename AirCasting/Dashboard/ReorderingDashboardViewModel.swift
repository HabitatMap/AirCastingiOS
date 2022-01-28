// Created by Lunar on 28/01/2022.
//

import Foundation

class ReorderingDashboardViewModel: ObservableObject {
    @Published var sessions: [SessionEntity]
    
    @Published var currentSession: SessionEntity?
    
    init(sessions: [SessionEntity]) {
        self.sessions = sessions
    }
}
