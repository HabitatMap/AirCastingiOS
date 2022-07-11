// Created by Lunar on 04/04/2022.
//

import Foundation
import SwiftUI
import Resolver

class BottomCardViewModel: ObservableObject {
    @InjectedObject private var userSettings: UserSettings
    @Published private var isModalScreenPresented = false
    let dataModel: BottomCardModel
    let session: PartialExternalSession
    
    init(session: PartialExternalSession) {
        dataModel = .init(id: session.id, title: session.name, startTime: session.startTime, endTime: session.endTime)
        self.session = session
    }
    
    func getIsModalScreenPresented() -> Bool { isModalScreenPresented }
    func setIsModalScreenPresented(using v: Bool) { isModalScreenPresented = v }
    
    func sessionCardTapped() {
        setIsModalScreenPresented(using: true)
    }
    
    func adaptTimeAndDate() -> String {
        var formatter: DateIntervalFormatter {
            if userSettings.twentyFourHour { return DateFormatters.SessionCardView.utcDateIntervalFormatter }
            return DateFormatters.SessionCardView.utcDateInterval12hFormatter
        }
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
