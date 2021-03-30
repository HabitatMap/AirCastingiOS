//
//  MeaurementStreamExtension.swift
//  AirCasting
//
//  Created by Lunar on 30/03/2021.
//

import Foundation


extension MeasurementStream {
    
    var latestValue: Double? {
        guard let all = measurements?.allObjects as? [Measurement] else { return nil }
        
        let sorted = all.sorted { (a, b) -> Bool in
            guard let atime = a.time,
                  let btime = b.time else { return false }
           return atime < btime
        }
        return sorted.last?.value
    }
}
