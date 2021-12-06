// Created by Lunar on 02/12/2021.
//

import Foundation

protocol SDRestartABViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var urlProvider: BaseURLProvider { get }
    var isSDClearProcess: Bool { get set }
}

class SDRestartABViewModelDefault: SDRestartABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    @Published var isSDClearProcess: Bool
    let urlProvider: BaseURLProvider
    
    init(urlProvider: BaseURLProvider, isSDClearProcess: Bool) {
        self.urlProvider = urlProvider
        self.isSDClearProcess = isSDClearProcess
    }
}
