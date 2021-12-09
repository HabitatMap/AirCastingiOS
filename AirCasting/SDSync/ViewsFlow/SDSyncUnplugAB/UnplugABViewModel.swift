// Created by Lunar on 08/12/2021.
//

import Foundation

protocol UnplugABViewModel: ObservableObject {
    var presentNextScreen: Bool { get }
    var urlProvider: BaseURLProvider { get }
    func continueButtonTapped()
}

class UnplugABViewModelDefault: UnplugABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    
    init(urlProvider: BaseURLProvider) {
        self.urlProvider = urlProvider
    }
    
    func continueButtonTapped() {
        presentNextScreen.toggle()
    }
}

class UnplugABViewModelDummy: UnplugABViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    
    init() {
        self.urlProvider = DummyURLProvider()
    }
    
    func continueButtonTapped() { }
}
