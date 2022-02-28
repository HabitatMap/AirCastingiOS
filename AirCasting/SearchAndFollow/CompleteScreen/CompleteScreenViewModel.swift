// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI

class CompleteScreenViewModel: ObservableObject {
    let session: SearchSession
    
    init(session: SearchSession) {
        self.session = session
    }
}
