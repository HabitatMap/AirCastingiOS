// Created by Lunar on 02/12/2021.
//

import Foundation
import Resolver

class SDRestartABViewModel: ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let isSDClearProcess: Bool
    
    init(isSDClearProcess: Bool) {
        self.isSDClearProcess = isSDClearProcess
    }
    
    func continueSyncFlow() {
       presentNextScreen = true
    }
}
