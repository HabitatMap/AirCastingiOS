// Created by Lunar on 04/04/2022.
//

import Foundation
import SwiftUI
import Resolver

class BottomCardViewModel: ObservableObject {
    @Published private var isModalScreenPresented = false
    let dataModel: BottomCardModel
    let session: PartialExternalSession
    
    init(session: PartialExternalSession) {
        dataModel = .init(id: session.id, title: session.name, startTime: session.startTime, endTime: session.endTime)
        self.session = session
    }
    
    func getIsModalScreenPresented() -> Bool { isModalScreenPresented }
    //TODO: Fix warning - Publishing changes from within view updates is not allowed, this will cause undefined behavior.
    func setIsModalScreenPresented(using v: Bool) { isModalScreenPresented = v }
    
    func sessionCardTapped() {
        setIsModalScreenPresented(using: true)
    }
    
    func adaptTimeAndDate() -> String {
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter 
        let start = dataModel.startTime
        let end = dataModel.endTime
        let string = formatter.string(from: start, to: end)
        return string
    }
    
    func initCompleteScreen() -> CompleteScreen {
        CompleteScreen(session: session) { [weak self] in
            self?.isModalScreenPresented = false
        }
    }
}
