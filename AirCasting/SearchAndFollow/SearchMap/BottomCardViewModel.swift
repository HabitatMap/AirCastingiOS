// Created by Lunar on 04/04/2022.
//

import Foundation
import SwiftUI

class BottomCardViewModel: ObservableObject {
    @Published private var isModalScreenPresented = false
    let dataModel: BottomCardModel
    
    init(id: Int, uuid: String, title: String, startTime: String, endTime: String, latitude: Double, longitude: Double) {
        dataModel = .init(id: id, uuid: uuid, title: title, startTime: startTime, endTime: endTime, latitude: latitude, longitude: longitude)
    }
    
    func getIsModalScreenPresented() -> Bool { isModalScreenPresented }
    func setIsModalScreenPresented(using v: Bool) { isModalScreenPresented = v }
    
    func sessionCardTapped() {
        setIsModalScreenPresented(using: true)
    }
    
    func adaptTimeAndDate() -> String {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        let start = startTimeAsDate()
        let end = endTimeAsDate()
        let string = formatter.string(from: start, to: end)
        return string
    }
    
    func startTimeAsDate() -> Date {
        let formatter = DateFormatters.SearchAndFollow.timeFormatter
        let date = formatter.date(from: dataModel.startTime)
        guard let d = date else { return DateBuilder.getFakeUTCDate() }
        return d
    }
    
    func endTimeAsDate() -> Date {
        let formatter = DateFormatters.SearchAndFollow.timeFormatter
        let date = formatter.date(from: dataModel.endTime)
        guard let d = date else { return DateBuilder.getFakeUTCDate() }
        return d
    }
    
    func initCompleteScreen() -> CompleteScreen {
        CompleteScreen(session: .init(uuid: "\(dataModel.uuid)",
                                      provider: "OpenAir",
                                      name: dataModel.title,
                                      startTime: startTimeAsDate(),
                                      endTime: endTimeAsDate(),
                                      longitude: dataModel.longitude,
                                      latitude: dataModel.latitude,
                                      sensorName: "OpenAir-PM2.5"),
                       isPresented: .init(get: {
            self.getIsModalScreenPresented()
        }, set: { value in
            self.setIsModalScreenPresented(using: value)
        }))
    }
}
