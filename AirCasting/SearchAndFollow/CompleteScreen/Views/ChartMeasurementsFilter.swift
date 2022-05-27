// Created by Lunar on 23/05/2022.
//

import Foundation
import SwiftUI

protocol ChartMeasurementsFilter {
    func filter(measurements: [SearchAndFollowChartViewModel.ChartMeasurement]) -> [SearchAndFollowChartViewModel.ChartMeasurement]
}

struct ChartMeasurementsFilterDefault: ChartMeasurementsFilter {
    let name: String
    var convertedName: EntriesSensor { return getEntriesSensor(using: name) }
    typealias MeasurementType = SearchAndFollowChartViewModel.ChartMeasurement
    
    enum EntriesSensor: String {
        case OpenAQ = "OpenAQ"
        case AirBeam = "AirBeam"
        case PurpleAir = "PurpleAir"
        case undefined = ""
    }
    
    func filter(measurements: [MeasurementType]) -> [MeasurementType] {
        guard convertedName != .OpenAQ else { return measurements }
        guard let firstElement = measurements.reversed().first?.time else { return [] }
        switch convertedName {
        case .AirBeam, .PurpleAir:
            return clearData(using: measurements, hourToRemove: firstElement)
        case .undefined:
            Log.info("Missing sensor name in the chart VM")
            return []
        default:
            Log.info("Missing sensor name in the chart VM")
            return []
        }
    }
    
    private func hoursForRemoval(using element: Date) -> Int { Calendar.current.component(.hour, from: element) }
    
    private func clearData(using measurements: [MeasurementType], hourToRemove: Date) -> [MeasurementType] {
        var updatedMeasurements = measurements
        for (index, item) in updatedMeasurements.enumerated().reversed() {
            if Calendar.current.component(.hour, from: item.time) == hoursForRemoval(using: hourToRemove) {
                updatedMeasurements.remove(at: index)
                continue
            }
            break
        }
        return updatedMeasurements
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
