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
        case Government = "Government"
        case AirBeam = "AirBeam"
        case undefined = ""
    }
    
    func filter(measurements: [MeasurementType]) -> [MeasurementType] {
        guard let firstElement = measurements.reversed().first?.time else { return [] }
        switch convertedName {
        case .AirBeam, .Government:
            return clearData(using: measurements, hourToRemove: firstElement)
        case .undefined:
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
        if (sensor == "AirBeamMini") { return .AirBeam }
            
        switch sensor {
        case EntriesSensor.Government.rawValue: return .Government
        case EntriesSensor.AirBeam.rawValue: return .AirBeam
        default: return .undefined
        }
    }
}
