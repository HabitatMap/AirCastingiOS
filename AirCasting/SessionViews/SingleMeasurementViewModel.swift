// Created by Lunar on 26/01/2022.
//

import Foundation
import Combine

class SingleMeasurementViewModel: ObservableObject {
    let settings: UserSettings
    private var cancellables: [AnyCancellable] = []
    
    init(settings: UserSettings) {
        self.settings = settings
        setupHooks()
    }
    
    private func setupHooks() {
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
}
