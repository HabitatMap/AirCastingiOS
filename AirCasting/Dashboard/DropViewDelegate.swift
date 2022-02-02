// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct DropViewDelegate: DropDelegate {
    
    let session: SessionEntity
    @Binding var currentSession: SessionEntity?
    @Binding var sessions: [SessionEntity]
    @Binding var changedView: Bool
    
    func dropEntered(info: DropInfo) {
        changedView = true
        
        let fromIndex = sessions.firstIndex { (session) -> Bool in
            return session.uuid == currentSession?.uuid
        } ?? 0
        
        let toIndex = sessions.firstIndex { (session) -> Bool in
            return session.uuid == self.session.uuid
        } ?? 0
        
        if fromIndex != toIndex {
            withAnimation(.default) {
                let fromPage = sessions[fromIndex]
                sessions[fromIndex] = sessions[toIndex]
                sessions[toIndex] = fromPage
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    
    func performDrop(info: DropInfo) -> Bool {
        currentSession = nil
        return true
    }
}

struct DropOutsideOfGridDelegate: DropDelegate {
    
    @Binding var currentSession: SessionEntity?
    
    func performDrop(info: DropInfo) -> Bool {
        currentSession = nil
        return true
    }
}
