// Created by Lunar on 27/05/2021.
//

import Foundation
import CoreData
import Resolver

final class SessionDataEraser: ObservableObject {
    @Injected private var persistenceController: PersistenceController

    func clearAllSessions(completion: ((Result<Void, Error>) -> Void)?) {
        let context = persistenceController.editContext
        context.perform({
            do {
                let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
                let sessions = try context.fetch(request)
                sessions.forEach(context.delete)
                
                let externalSessionsRequest = ExternalSessionEntity.fetchRequest()
                let externalSessions = try context.fetch(externalSessionsRequest)
                externalSessions.forEach(context.delete)
                try context.save()
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        })
    }
}

extension SessionDataEraser: DataEraser {
    func eraseAllData(completion: ((Result<Void, Error>) -> Void)?) {
        clearAllSessions(completion: completion)
    }
}
