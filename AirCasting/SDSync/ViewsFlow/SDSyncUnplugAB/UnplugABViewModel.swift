// Created by Lunar on 08/12/2021.
//

import Foundation

protocol UnplugABViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var urlProvider: BaseURLProvider { get }
}

class UnplugABViewModelDefault: UnplugABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    
    init(urlProvider: BaseURLProvider) {
        self.urlProvider = urlProvider
    }
}

class UnplugABViewModelDummy: UnplugABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    
    init() {
        self.urlProvider = DummyURLProvider()
    }
}
