// Created by Lunar on 08/12/2021.
//

import Foundation

class UnplugABViewModel: ObservableObject {

    @Published var presentNextScreen: Bool = false
    var isSDClearProcess: Bool
    
    init(isSDClearProcess: Bool) {
        self.isSDClearProcess = isSDClearProcess
    }
    
    func continueButtonTapped() {
        presentNextScreen.toggle()
    }
}
