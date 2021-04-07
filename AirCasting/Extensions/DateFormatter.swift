//
//  DateFormatter.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation


extension ISO8601DateFormatter {
    
    static var defaultLong: ISO8601DateFormatter {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter
    }
}
