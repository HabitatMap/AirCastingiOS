// Created by Lunar on 02/12/2021.
//

import Foundation

protocol BackendSyncCompletedViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var urlProvider: BaseURLProvider { get }
}

class BackendSyncCompletedViewModelDefault: BackendSyncCompletedViewModel, ObservableObject {
    
    @Published var presentNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    
    init(urlProvider: BaseURLProvider) {
        self.urlProvider = urlProvider
    }
}
