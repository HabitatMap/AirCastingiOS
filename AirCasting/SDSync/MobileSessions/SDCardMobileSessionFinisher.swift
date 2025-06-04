// Created by Lunar on 4.06.25.
//

import Foundation
import Resolver
import CoreData


protocol SessionFinisher {
    func callAsFunction(uuid: SessionUUID) throws
}

class SDCardMobileSessionFinisher : SessionFinisher {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    
    func callAsFunction(uuid: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: uuid)
        if (sessionEntity.isInStandaloneMode) {
            sessionEntity.status = .FINISHED
            guard let endTime = sessionEntity.lastMeasurementTime else { return }
            Log.info("SD Sync end time for session (UUID | name) \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
            sessionEntity.endTime = endTime
        }
    }
}
