// Created by Lunar on 01/12/2021.
//

import Foundation
import CoreLocation

struct SDCardMeasurementsRow {
    let sessionUUID: SessionUUID
    let date: Date
    let lat: Double
    let long: Double
    let f: Double
    let rh: Double
    let pm1: Double
    let pm2_5: Double
    let pm10: Double
}

class SDCardMeasurementsParser {
    func parseMeasurement(lineString: String) -> SDCardMeasurementsRow? {
        let measurementInfo = lineString.split(separator: ",")
        guard measurementInfo.count == 13 else {
            Log.warning("Line corrupted: \(lineString)")
            return nil
        }
        guard
            let sessionUUID = SessionUUID(uuidString: String(measurementInfo[SDCardCSVFileFactory.Header.uuid.rawValue])),
            let date = SDParsingUtils.dateFrom(date: measurementInfo[SDCardCSVFileFactory.Header.date.rawValue],
                                               time: measurementInfo[SDCardCSVFileFactory.Header.time.rawValue]),
            let lat = Double(measurementInfo[SDCardCSVFileFactory.Header.latitude.rawValue]),
            let long = Double(measurementInfo[SDCardCSVFileFactory.Header.longitude.rawValue]),
            let f = Double(measurementInfo[SDCardCSVFileFactory.Header.f.rawValue]),
            let rh = Double(measurementInfo[SDCardCSVFileFactory.Header.rh.rawValue]),
            let pm1 = Double(measurementInfo[SDCardCSVFileFactory.Header.pm1.rawValue]),
            let pm2_5 = Double(measurementInfo[SDCardCSVFileFactory.Header.pm2_5.rawValue]),
            let pm10 = Double(measurementInfo[SDCardCSVFileFactory.Header.pm10.rawValue])
        else {
            Log.warning("Wrong data format in the csv row: \(lineString)")
            return nil
        }
        return SDCardMeasurementsRow(sessionUUID: sessionUUID,
                                     date: date,
                                     lat: lat,
                                     long: long,
                                     f: f,
                                     rh: rh,
                                     pm1: pm1,
                                     pm2_5: pm2_5,
                                     pm10: pm10)
    }
    
    func getUUID(lineString: String) -> String? {
        let measurementInfo = lineString.split(separator: ",")
        guard measurementInfo.count == 13 else {
            Log.warning("Line corrupted: \(lineString)")
            return nil
        }
        
        return String(measurementInfo[SDCardCSVFileFactory.Header.uuid.rawValue])
    }
}

class SDParsingUtils {
    static func dateFrom(date: Substring, time: Substring) -> Date? {
        let isoDate = String(date + "T" + time)
        let dateFormatter = DateFormatters.SDCardSync.fileParserFormatter
        let date = dateFormatter.date(from: isoDate)
        return date?.currentUTCTimeZoneDate
    }
}
