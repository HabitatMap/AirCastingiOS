// Created by Lunar on 04/04/2022.
//

import Foundation
import SwiftUI
import Resolver

class BottomCardViewModel: ObservableObject {
    let dataModel: BottomCardModel
    let session: PartialExternalSession
    
    init(session: PartialExternalSession) {
        dataModel = .init(id: session.id, title: session.name, startTime: session.startTime, endTime: session.endTime)
        self.session = session
    }
    
    func adaptTimeAndDate() -> String {
        // TO SIE TRIGGERUJE TUŻ PRZED?!
        
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter
        let start = dataModel.startTime
        let end = dataModel.endTime
        let string = formatter.string(from: start, to: end)
        return string
    }
    
    func initCompleteScreen() -> CompleteScreen {
        CompleteScreen(session: session)
    }
}
