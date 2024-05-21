// Created by Lunar on 11/03/2024.
//

import Foundation
import CoreLocation
import Resolver

class MiniSDCardMeasurementsParser: SDMeasurementsParser {
    let numberOfColumnsInTheFile = 4
    let firstLineColumns = 1
    
    func enumerateMeasurements(url: URL, action: (SDCardMeasurementsRow) -> Void) throws {
        let lineReader = Resolver.resolve(FileLineReader.self)
        var lastKnownUUID: SessionUUID?
        try lineReader.readLines(of: url) { result in
            switch result {
            case .line(let lineString):
                // Reading from file
                let measurementInfo = lineString.split(separator: ",")
                if measurementInfo.count == firstLineColumns,
                   let uuidString = getUUID(lineString: lineString) {
                    lastKnownUUID = SessionUUID(rawValue: uuidString)
                } else {
                    guard let lastKnownUUID, let measurements = parseMeasurement(lineString: lineString,
                                                              sessionUUID: lastKnownUUID) else { return }
                    action(measurements)
                }
            case .endOfFile: break
            }
        }
    }
    
    private func parseMeasurement(lineString: String, sessionUUID: SessionUUID) -> SDCardMeasurementsRow? {
        let measurementInfo = lineString.split(separator: ",")
        guard measurementInfo.count == numberOfColumnsInTheFile else {
            Log.warning("Line corrupted: \(lineString)")
            return nil
        }
        guard let date = SDParsingUtils.dateFrom(date: measurementInfo[MiniSDCardCSVFileFactory.Header.date],
                                               time: measurementInfo[MiniSDCardCSVFileFactory.Header.time]),
            let pm1 = Double(measurementInfo[MiniSDCardCSVFileFactory.Header.pm1]),
            let pm2_5 = Double(measurementInfo[MiniSDCardCSVFileFactory.Header.pm2_5])
        else {
            Log.warning("Wrong data format in the csv row: \(lineString)")
            return nil
        }
        return SDCardMeasurementsRow(sessionUUID: sessionUUID,
                                     date: date,
                                     pm1: pm1,
                                     pm2_5: pm2_5)
    }
    
    private func getUUID(lineString: String) -> String? {
        let measurementInfo = lineString.split(separator: ",")
        guard measurementInfo.count == firstLineColumns else {
            Log.warning("Line corrupted: \(lineString)")
            return nil
        }
        return String(measurementInfo[MiniSDCardCSVFileFactory.Header.uuid])
    }
    
    func getMeasurementTime(lineString: String) -> Date? {
        let measurementInfo = lineString.split(separator: ",")
        guard measurementInfo.count == numberOfColumnsInTheFile else {
            Log.warning("Line corrupted: \(lineString)")
            return nil
        }
        return SDParsingUtils.dateFrom(date: measurementInfo[MiniSDCardCSVFileFactory.Header.date],
                                       time: measurementInfo[MiniSDCardCSVFileFactory.Header.time])
    }
    
    func enumerateSessionLines(lines: [String], action: (String?, String) -> Void) {
        var lastKnownUUID: String?
        lines.forEach { lineString in
            let measurementInfo = lineString.split(separator: ",")
            if measurementInfo.count == firstLineColumns {
               lastKnownUUID = getUUID(lineString: lineString)
            }
            action(lastKnownUUID, lineString)
        }
    }
}
