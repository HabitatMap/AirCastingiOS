// Created by Lunar on 01/12/2022.
//

import Foundation
import Resolver
import CoreData

protocol SessionCreatingStorage {
    func accessStorage(_ task: @escaping(HiddenSessionCreatingStorage) -> Void)
}

protocol HiddenSessionCreatingStorage {
    func save() throws
    func createSession(_ session: Session) throws
}

class DefaultSessionCreatingStorage: SessionCreatingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSessionCreatingStorage = DefaultHiddenSessionCreatingStorage(context: self.context)
    
    /// All actions performed on HiddenSessionCreatingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSessionCreatingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}


class DefaultHiddenSessionCreatingStorage: HiddenSessionCreatingStorage {
    @Injected private var updateSessionParamsService: UpdateSessionParamsService
    private let context: NSManagedObjectContext
    
    enum Error: Swift.Error {
        case missingSensorName
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save() throws {
        guard context.hasChanges else { return }
        try self.context.save()
    }
    
    func createSession(_ session: Session) throws {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
    }
    
    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
}
