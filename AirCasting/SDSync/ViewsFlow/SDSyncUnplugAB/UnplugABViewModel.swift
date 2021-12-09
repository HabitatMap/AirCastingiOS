// Created by Lunar on 08/12/2021.
//

import Foundation

protocol UnplugABViewModel: ObservableObject {
    var presentNextScreen: Bool { get }
    var urlProvider: BaseURLProvider { get }
    var isSDClearProcess: Bool { get set }
    func continueButtonTapped()
}

class UnplugABViewModelDefault: UnplugABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    var isSDClearProcess: Bool
    
    init(urlProvider: BaseURLProvider, isSDClearProcess: Bool) {
        self.urlProvider = urlProvider
        self.isSDClearProcess = isSDClearProcess
    }
    
    func continueButtonTapped() {
        presentNextScreen.toggle()
    }
}

class UnplugABViewModelDummy: UnplugABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    var isSDClearProcess = false
    
    init() {
        self.urlProvider = DummyURLProvider()
    }
    
    func continueButtonTapped() { }
}
