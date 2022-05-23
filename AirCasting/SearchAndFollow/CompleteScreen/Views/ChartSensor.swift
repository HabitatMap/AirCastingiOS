// Created by Lunar on 23/05/2022.
//

import Foundation
import SwiftUI

protocol ChartSensor {
    func clean(measurements: inout [ChartMeasurement])
}

struct ChartSensorDefault: ChartSensor {
    let name: String
    var convertedName: EntriesSensor { return getEntriesSensor(using: name) }
    
    enum EntriesSensor: String {
        case OpenAQ = "OpenAQ"
        case AirBeam = "AirBeam"
        case PurpleAir = "PurpleAir"
        case undefined = ""
    }
    
    func clean(measurements: inout [ChartMeasurement]) {
        guard convertedName != .OpenAQ else { return }
        guard let firstElement = measurements.reversed().first?.time else { return }
        switch convertedName {
        case .AirBeam:
            // AB stands for AirBeam
            clearABData(using: &measurements, hourToRemove: firstElement)
        case .PurpleAir:
            // PA stands for PurpleAir
            clearPAData(using: &measurements, hourToRemove: firstElement)
        case .undefined:
            Log.info("Missing sensor name in the chart VM")
        default:
            Log.info("Missing sensor name in the chart VM")
            return
        }
    }
    
    private func hoursForRemoval(using element: Date) -> Int { Calendar.current.component(.hour, from: element) }
    
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
    
    private func getEntriesSensor(using sensor: String) -> EntriesSensor {
        switch sensor {
        case EntriesSensor.OpenAQ.rawValue: return .OpenAQ
        case EntriesSensor.AirBeam.rawValue: return .AirBeam
        case EntriesSensor.PurpleAir.rawValue: return .PurpleAir
        default: return .undefined
        }
    }
}
