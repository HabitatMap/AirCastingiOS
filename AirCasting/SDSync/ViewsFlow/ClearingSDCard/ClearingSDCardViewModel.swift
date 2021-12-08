// Created by Lunar on 06/12/2021.
//
import Foundation

protocol ClearingSDCardViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var isSDClearProcess: Bool { get set }
}

class ClearingSDCardViewModelDefault: ClearingSDCardViewModel, ObservableObject {

    var isSDClearProcess: Bool
    @Published var presentNextScreen: Bool = false
    
    init(isSDClearProcess: Bool) {
        self.isSDClearProcess = isSDClearProcess
    }
}
