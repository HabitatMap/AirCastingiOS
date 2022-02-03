// Created by Lunar on 28/01/2022.
//

import SwiftUI

struct DropViewDelegate: DropDelegate {
    
    let sessionAtDropDestination: SessionEntity
    @Binding var currentlyDraggedSession: SessionEntity?
    @Binding var sessions: [SessionEntity]
    @Binding var changedView: Bool
    
    func dropEntered(info: DropInfo) {
        changedView = true
        
        let fromIndex = sessions.firstIndex { (session) -> Bool in
            return session.uuid == currentlyDraggedSession?.uuid
        } ?? 0
        
        let toIndex = sessions.firstIndex { (session) -> Bool in
            return session.uuid == sessionAtDropDestination.uuid
        } ?? 0
        
        guard fromIndex != toIndex else { return }
        
        withAnimation(.default) { sessions.swapAt(fromIndex, toIndex) }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    
    func performDrop(info: DropInfo) -> Bool {
        currentlyDraggedSession = nil
        return true
    }
}

struct DropOutsideOfGridDelegate: DropDelegate {
    
    @Binding var currentlyDraggedSession: SessionEntity?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        currentlyDraggedSession = nil
        return true
    }
}
