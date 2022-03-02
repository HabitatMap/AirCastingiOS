// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI

class CompleteScreenViewModel: ObservableObject {
    let session: SearchSession
    @Published var selectedStream: Int?
    @Published var isMapSelected: Bool = true
    
    init(session: SearchSession) {
        self.session = session
        selectedStream = session.streams.first?.id
    }
    
    func stream(withID id: Int?) -> SearchSession.SearchSessionStream {
        if let streamId = id, let rightStream = session.streams.first(where: { $0.id == streamId}) {
            return rightStream
        } else {
            return session.streams.first!
        }
    }
    
    func mapTapped() {
        isMapSelected.toggle()
    }
    
    func chartTapped() {
        isMapSelected.toggle()
    }
}
