// Created by Lunar on 26/04/2022.
//

import Foundation

struct MeasurementsDownloaderResultModel: Decodable {
    let id: Int
    let streams: [Stream]
    
    struct Stream: Decodable {
        let stream_id: Int
        let sensor_name: String
        let threshold_very_low: Int32
        let threshold_low: Int32
        let threshold_medium: Int32
        let threshold_high: Int32
        let threshold_very_high: Int32
        let unit_name: String
        let measurement_short_type: String
        let measurement_type: String
        let sensor_unit: String
    }
}

