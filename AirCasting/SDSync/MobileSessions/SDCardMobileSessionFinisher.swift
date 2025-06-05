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
        
        guard sessionEntity.isInStandaloneMode else { Log.info("SD Sync tried finish \(uuid) which is not in standalone mode!"); return }
        
        sessionEntity.status = .FINISHED
        guard let endTime = sessionEntity.lastMeasurementTime else { return }
        Log.info("SD Sync measurement end time for session (UUID | name) \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
        sessionEntity.endTime = endTime
    }
}
