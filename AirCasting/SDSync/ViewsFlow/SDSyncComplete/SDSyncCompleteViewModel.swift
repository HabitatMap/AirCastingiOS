// Created by Lunar on 06/12/2021.
//

import Foundation

protocol SDSyncCompleteViewModel: ObservableObject {
    var creatingSessionFlowContinues: Bool { get }
}

class SDSyncCompleteViewModelDefault: SDSyncCompleteViewModel, ObservableObject {
    
    @Published var creatingSessionFlowContinues: Bool = false
    
}
