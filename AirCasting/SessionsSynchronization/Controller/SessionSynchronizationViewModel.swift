// Created by Lunar on 09/09/2021.
//

import Foundation
import Combine
import Resolver

class SessionSynchronizationViewModel: ObservableObject {
    @Published public var syncInProgress: Bool = true
    private var cancellables = [AnyCancellable]()
    
    init() {
        let syncSessionController = Resolver.resolve(SessionSynchronizer.self)
        syncSessionController.syncInProgress.receive(on: DispatchQueue.main).sink { [weak self] value in
            self?.syncInProgress = value
        }.store(in: &cancellables)
    }
}
