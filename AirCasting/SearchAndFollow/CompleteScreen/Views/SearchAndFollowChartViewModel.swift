// Created by Lunar on 28/02/2022.
//

import Foundation
import SwiftUI

class SearchAndFollowChartViewModel: ObservableObject {
    struct ChartDot {
        let value: Double
        let color: Color
    }
    
    struct ChartMeasurement {
        let value: Double
        let time: Date
    }
    
    enum EntriesSensor: String {
        case OpenAQ = "OpenAQ"
        case AirBeam = "AirBeam"
        case PurpleAir = "PurpleAir"
        case undefined = ""
    }
    
    @Published var entries: [ChartDot] = []
    
    let numberOfEntries = 9
    
    func generateEntries(with measurements: [ChartMeasurement], thresholds: ThresholdsValue, basedOn sensorName: String) -> (Date?, Date?) {
        var times: [Date] = []
        var buffer: [ChartMeasurement] = []
        var updatedMeasurements = measurements
        
        let sensor = getEntriesSensor(using: sensorName)
        if sensor != .OpenAQ {
            guard let firstElement = updatedMeasurements.reversed().first?.time else { return (nil, nil) }
            
            switch sensor {
            case .AirBeam:
                // AB stands for AirBeam
                clearABData(using: &updatedMeasurements, hourToRemove: firstElement)
            case .PurpleAir:
                // PA stands for PurpleAir
                clearPAData(using: &updatedMeasurements, hourToRemove: firstElement)
            case .undefined:
                Log.info("Missing sensor name in the chart VM")
            default:
                return (nil, nil)
            }
        }
        
        for measurement in updatedMeasurements.reversed() {
            if entries.count == 9 {
                break
            }
            
            if buffer.isEmpty || hourIsAlreadyPresent(in: buffer.map({ $0.time }), date: measurement.time) {
                buffer.append(measurement)
                continue
            }
            
            addAverage(for: buffer, times: &times, thresholds: thresholds)
            
            buffer = [measurement]
        }
        
        if entries.count < 9 && !buffer.isEmpty {
            addAverage(for: buffer, times: &times, thresholds: thresholds)
        }
        
        entries.reverse()
        return (startTime: times.min(), endTime: times.max())
    }
    
    private func getEntriesSensor(using sensor: String) -> EntriesSensor {
        switch sensor {
        case EntriesSensor.OpenAQ.rawValue: return .OpenAQ
        case EntriesSensor.AirBeam.rawValue: return .AirBeam
        case EntriesSensor.PurpleAir.rawValue: return .PurpleAir
        default: return .undefined
        }
    }
    
    private func clearPAData(using updatedMeasurements: inout [ChartMeasurement], hourToRemove: Date) {
        for (index, item) in updatedMeasurements.enumerated().reversed() {
            if Calendar.current.component(.hour, from: item.time) == hoursForRemoval(using: hourToRemove) && Calendar.current.component(.minute, from: item.time) != 00 {
                updatedMeasurements.remove(at: index)
            }
        }
    }
    
    private func clearABData(using updatedMeasurements: inout [ChartMeasurement], hourToRemove: Date) {
        for (index, item) in updatedMeasurements.enumerated().reversed() {
            if Calendar.current.component(.hour, from: item.time) == hoursForRemoval(using: hourToRemove) {
                updatedMeasurements.remove(at: index)
                continue
            }
            break
        }
    }
    
    private func hoursForRemoval(using element: Date) -> Int { Calendar.current.component(.hour, from: element) }
    
    private func addAverage(for buffer: [ChartMeasurement], times: inout [Date], thresholds: ThresholdsValue) {
        guard !buffer.isEmpty else { return }
        let average = round((buffer.map { $0.value }.reduce(0, +)) / Double(buffer.count))
        
        times.append(buffer.last!.time.roundedUpToHour)
        entries.append(ChartDot(value: Double(average), color: thresholds.colorFor(value: average)))
    }
    
    private func hourIsAlreadyPresent(in times: [Date], date: Date) -> Bool {
        let nowComponent = Calendar.current.component(.hour, from: date)
        let hoursAlreadyPresent = times.map { Calendar.current.component(.hour, from: $0) }
        return hoursAlreadyPresent.contains(nowComponent)
    }
}
