// Created by Lunar on 09/09/2021.
//

import Foundation

protocol SessionSynchronizationViewModel {
    var syncInProgress: Bool { get }
}

class DefaultSessionSynchronizationViewModel: SessionSynchronizationViewModel, ObservableObject {
    let syncControllerDecorator: SyncControllerDecorator
    @Published public var syncInProgress: Bool
    
    init(syncControllerDecorator: SyncControllerDecorator) {
        self.syncControllerDecorator = syncControllerDecorator
        self.syncInProgress = syncControllerDecorator.isCurrentlySynchronizing
    }
}

class SyncControllerDecorator {
    let syncSessionController: SessionSynchronizationController
    @Published var isCurrentlySynchronizing: Bool
    
    init(syncSessionController: SessionSynchronizationController) {
        self.syncSessionController = syncSessionController
        self.isCurrentlySynchronizing = syncSessionController.syncInProgress
    }
}
