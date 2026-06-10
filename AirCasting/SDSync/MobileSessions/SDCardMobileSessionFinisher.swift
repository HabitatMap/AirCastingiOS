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
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    private lazy var context: NSManagedObjectContext = persistenceController.editContext

    func callAsFunction(uuid: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: uuid)

        guard sessionEntity.isInStandaloneMode else { Log.info("SD Sync tried finish \(uuid) which is not in standalone mode!"); return }

        sessionEntity.status = .FINISHED
        if let endTime = sessionEntity.lastMeasurementTime {
            Log.info("SD Sync measurement end time for session (UUID | name) \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
            sessionEntity.endTime = endTime
        }

        // `activeSession` lingers across the RECORDING→DISCONNECTED flip done
        // by `SessionManagingReconnectionController.didStartReconnecting`
        // (which only mutates DB status — not the in-memory active-session
        // reference). After this finisher writes FINISHED, the post-sync
        // disconnect would otherwise hit `shouldReconnect == true` (the
        // stale `activeSession.device.uuid` still matches) and the
        // auto-reconnect chain would resume recording behind the wizard.
        // Clear the reference here so the chain skips this device.
        if activeSessionProvider.activeSession?.session.uuid == uuid {
            activeSessionProvider.clearActiveSession()
        }
    }
}
