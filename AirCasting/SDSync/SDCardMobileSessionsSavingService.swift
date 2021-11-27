// Created by Lunar on 26/11/2021.
//

import Foundation

struct SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    private let fileLineReader = DefaultFileLineReader()
    
    func saveDataToDb(fileURL: URL) {
        do {
            try fileLineReader.readLines(of: fileURL, progress: { line in
                switch line {
                case .line(let content):
                    let measurementInfo = content.split(separator: ",")
                    guard measurementInfo.count == 13 else {
                        Log.info("Line corrupted")
                        return
                    }
                    let sessionUUID = measurementInfo[1]
                    // if there is no session with this UUID in the DB then ignore the measurement
                    let date = measurementInfo[2]
                    let time = measurementInfo[3]
                    // if data and time is later than the session end time then ignore the measurement
                    // else save measurements to appropriate streams
                    let lat = measurementInfo[4]
                    let long = measurementInfo[5]
                    let f = measurementInfo[6]
                    let rh = measurementInfo[7]
                    let pm1 = measurementInfo[8]
                    let pm2_5 = measurementInfo[9]
                    let pm10 = measurementInfo[10]
                case .endOfFile:
                    return
                }
            })
        } catch {
            Log.error("Error reading file")
        }
    }
    
    
}
