// Created by Lunar on 27/05/2021.
//

import Foundation
import CoreData

final class SessionStorage: ObservableObject {
    let persistenceController: PersistenceController
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    func clearAllSessions(completion: ((Result<Void, Error>) -> Void)?) {
        let context = persistenceController.editContext
        context.perform({
            do {
                let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
                let sessions = try context.fetch(request)
                sessions.forEach(context.delete)
                try context.save()
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        })
    }
}
