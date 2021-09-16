// Created by Lunar on 09/09/2021.
//

import Foundation

protocol SessionSynchronizationViewModel {
    var syncInProgress: Bool { get }
}

class DefaultSessionSynchronizationViewModel: SessionSynchronizationViewModel, ObservableObject {
    let syncSessionController: SessionSynchronizationController
    let syncControllerDecorator: SyncControllerDecorator
    @Published public var syncInProgress: Bool {
        didSet {
            syncInProgress = syncSessionController.syncInProgress
        }
    }
    
    init(syncSessionController: SessionSynchronizationController) {
        self.syncSessionController = syncSessionController
        self.syncControllerDecorator = SyncControllerDecorator(syncSessionController: syncSessionController)
        self.syncInProgress = syncSessionController.syncInProgress
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
