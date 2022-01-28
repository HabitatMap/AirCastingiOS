// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct DropViewDelegate: DropDelegate {
    
    var session: SessionEntity
    var sessionsData: ReorderingDashboardViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        print(session.name)
        let fromIndex = sessionsData.sessions.firstIndex { (session) -> Bool in
            return session.uuid == sessionsData.currentSession?.uuid
        } ?? 0
        
        let toIndex = sessionsData.sessions.firstIndex { (session) -> Bool in
            return session.uuid == self.session.uuid
        } ?? 0
        
        if fromIndex != toIndex {
            withAnimation(.default) {
                let fromPage = sessionsData.sessions[fromIndex]
                sessionsData.sessions[fromIndex] = sessionsData.sessions[toIndex]
                sessionsData.sessions[toIndex] = fromPage
            }
        }
    }
}
