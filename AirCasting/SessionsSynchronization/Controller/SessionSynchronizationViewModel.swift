// Created by Lunar on 09/09/2021.
//

import Foundation
import Combine

protocol SessionSynchronizationViewModel: ObservableObject {
    var syncInProgress: Bool { get }
}

class DefaultSessionSynchronizationViewModel: SessionSynchronizationViewModel {
    @Published public var syncInProgress: Bool = true
    private var cancellables = [AnyCancellable]()
    
    init(syncSessionController: SessionSynchronizer) {
        syncSessionController.syncInProgress.receive(on: DispatchQueue.main).sink { [weak self] value in
            self?.syncInProgress = value
        }.store(in: &cancellables)
    }
}
