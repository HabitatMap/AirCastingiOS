// Created by Lunar on 01/12/2021.
//

import Foundation

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
    func parseMeasurement(lineSting: String) -> SDCardMeasurementsRow? {
        let measurementInfo = lineSting.split(separator: ",")
        guard measurementInfo.count == 13 else {
            Log.warning("Line corrupted: \(lineSting)")
            return nil
        }
        guard
            let sessionUUID = SessionUUID(uuidString: String(measurementInfo[1])),
            let date = dateFrom(date: measurementInfo[2], time: measurementInfo[3]),
            let lat = Double(measurementInfo[4]),
            let long = Double(measurementInfo[5]),
            let f = Double(measurementInfo[6]),
            let rh = Double(measurementInfo[9]),
            let pm1 = Double(measurementInfo[10]),
            let pm2_5 = Double(measurementInfo[11]),
            let pm10 = Double(measurementInfo[12])
        else {
            Log.warning("Wrong data format in the csv row: \(lineSting)")
            return nil
        }
        return SDCardMeasurementsRow(sessionUUID: sessionUUID, date: date, lat: lat, long: long, f: f, rh: rh, pm1: pm1, pm2_5: pm2_5, pm10: pm10)
    }
    
    private func dateFrom(date: Substring, time: Substring) -> Date? {
        let isoDate = String(date + "T" + time)
        let dateFormatter = DateFormatters.SDCardSync.fileParserFormatter
        let date = dateFormatter.date(from:isoDate)
        return date?.currentUTCTimeZoneDate
    }
}
