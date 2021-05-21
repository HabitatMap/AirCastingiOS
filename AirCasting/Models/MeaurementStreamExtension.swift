//
//  MeaurementStreamExtension.swift
//  AirCasting
//
//  Created by Lunar on 30/03/2021.
//

import Foundation


extension MeasurementStreamEntity {
    var latestMeasurementEntity: MeasurementEntity? {
        guard let all = measurements?.array as? [MeasurementEntity] else { return nil }

        let sorted = all.sorted { (a, b) -> Bool in
            guard let atime = a.time,
                  let btime = b.time else { return false }
            return atime < btime
        }
        return sorted.last
    }
    
    var latestValue: Double? {
        latestMeasurementEntity?.value
    }
}
