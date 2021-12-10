// Created by Lunar on 02/12/2021.
//

import Foundation

protocol SDRestartABViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    // urlProvider should should not be exposed
    // BUT it is - REASON: it is needed only to pass to some navigation view
    var urlProvider: BaseURLProvider { get }
    var isSDClearProcess: Bool { get set }
    func continueSyncFlow()
}

class SDRestartABViewModelDefault: SDRestartABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    var isSDClearProcess: Bool
    let urlProvider: BaseURLProvider
    
    init(urlProvider: BaseURLProvider, isSDClearProcess: Bool) {
        self.urlProvider = urlProvider
        self.isSDClearProcess = isSDClearProcess
    }
    
    func continueSyncFlow() {
       presentNextScreen = true
    }
    
    func continueSyncFlow() {
       presentNextScreen = true
    }
}
