// Created by Lunar on 04/04/2022.
//

import Foundation
import SwiftUI

class BottomCardViewModel: ObservableObject {
    @Published private var isModalScreenPresented = false
    let dataModel: BottomCardModel
    let sensorType: String
    let username: String
    
    init(id: Int, uuid: String, title: String, startTime: String, endTime: String, latitude: Double, longitude: Double, streamId: Int, streamUnitName: String, streamUnitSymbol: String, streamSensorName: String, streamSensorPackageName: String, thresholds: ThresholdsValue, sensorType: String, username: String) {
        dataModel = .init(id: id, uuid: uuid, title: title, startTime: startTime, endTime: endTime, latitude: latitude, longitude: longitude, stream: .init(id: streamId, unitName: streamUnitName, unitSymbol: streamUnitSymbol, sensorName: streamSensorName, sensorPackageName: streamSensorPackageName, thresholdVeryLow: thresholds.veryLow, thresholdLow: thresholds.low, thresholdMedium: thresholds.medium, thresholdHigh: thresholds.high, thresholdVeryHigh: thresholds.veryHigh), thresholds: thresholds)
        self.sensorType = sensorType
        self.username = username
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
                                      provider: username,
                                      name: dataModel.title,
                                      startTime: startTimeAsDate(),
                                      endTime: endTimeAsDate(),
                                      longitude: dataModel.longitude,
                                      latitude: dataModel.latitude,
                                      sensorName: sensorType,
                                      stream: PartialExternalSession.Stream(id: dataModel.stream.id, unitName: dataModel.stream.unitName, unitSymbol: dataModel.stream.unitSymbol, sensorName: dataModel.stream.sensorName, sensorPackageName: dataModel.stream.sensorPackageName, thresholdVeryLow: dataModel.stream.thresholdVeryLow, thresholdLow: dataModel.stream.thresholdLow, thresholdMedium: dataModel.stream.thresholdMedium, thresholdHigh: dataModel.stream.thresholdHigh, thresholdVeryHigh: dataModel.stream.thresholdVeryHigh),
                                      thresholdsValues: dataModel.thresholds)) { [weak self] in
            self?.isModalScreenPresented = false
        }
    }
}
