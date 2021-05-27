// Created by Lunar on 27/05/2021.
//

import Foundation
import CoreData

final class SessionStorage: ObservableObject {
    let persistenceController: PersistenceController
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    func clearAllSession() throws {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        let context = persistenceController.viewContext
        let sessions = try context.fetch(request)
        sessions.forEach(context.delete)
        try context.save()
    }

    // Uses NSBatchDeleteRequest not informing the native core data notification system
    func clearAllSessionSilently() throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: SessionEntity.fetchRequest())
        deleteRequest.resultType = .resultTypeObjectIDs
        let res = try persistenceController.editContext().execute(deleteRequest)
        Log.info("Deleted sessions \(res)")
        persistenceController.viewContext.reset()
    }
}
