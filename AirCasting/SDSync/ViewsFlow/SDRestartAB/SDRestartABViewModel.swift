// Created by Lunar on 02/12/2021.
//

import Foundation

protocol SDRestartABViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var urlProvider: BaseURLProvider { get }
}

class SDRestartABViewModelDefault: SDRestartABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    
    init(urlProvider: BaseURLProvider) {
        self.urlProvider = urlProvider
    }
}
