// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreLocation


struct SDSession {
    let uuid: SessionUUID
    let endTime: Date
    let new: Bool
}

struct SDStream: Hashable {
    let sessionUUID: SessionUUID
    let name: StreamName
}

enum StreamName {
    case f
    case rh
    case pm1
    case pm2_5
    case pm10
}

struct SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    private let fileLineReader = DefaultFileLineReader()
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func saveDataToDb(fileURL: URL) {
        var sessionsUUIDandTimes: [SDSession] = []
        var sessionsWithMeasurement: [SDStream: [Measurement]] = [:]
        measurementStreamStorage.accessStorage { storage in
            do {
                try fileLineReader.readLines(of: fileURL, progress: { line in
                    switch line {
                    case .line(let content):
                        let measurementInfo = content.split(separator: ",")
                        guard measurementInfo.count == 13 else {
                            Log.info("Line corrupted")
                            return
                        }
                        guard
                            let sessionUUID = SessionUUID(uuidString: String(measurementInfo[1])),
                            let date = dateFrom(date: measurementInfo[2], time: measurementInfo[3]),
                            let lat = Double(measurementInfo[4]),
                            let long = Double(measurementInfo[5]),
                            let f = Double(measurementInfo[6]),
                            let rh = Double(measurementInfo[7]),
                            let pm1 = Double(measurementInfo[8]),
                            let pm2_5 = Double(measurementInfo[9]),
                            let pm10 = Double(measurementInfo[10])
                        else {
                            Log.info("Wrong data format in the csv row")
                            return
                        }
                        
                        
                        var session = sessionsUUIDandTimes.first(where: {$0.uuid == sessionUUID })
                        if session == nil {
                            do {
                                if let sessionVar = try storage.getExistingSession(with: sessionUUID) {
                                    session = SDSession(uuid: sessionUUID, endTime: sessionVar.endTime ?? Date(), new: false)
                                } else {
                                    session = SDSession(uuid: sessionUUID, endTime: Date(), new: true)
                                }
                            } catch {
                                Log.error(error.localizedDescription)
                            }
                            
                            sessionsUUIDandTimes.append(session!)
                        }
                        
                        if date < session!.endTime {
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .f), default: []].append(Measurement(time: date, value: f, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .rh), default: []].append(Measurement(time: date, value: rh, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .pm1), default: []].append(Measurement(time: date, value: pm1, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .pm2_5), default: []].append(Measurement(time: date, value: pm2_5, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .pm10), default: []].append(Measurement(time: date, value: pm10, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                        }
                        
                        
                        
                    case .endOfFile:
                        return
                    }
                })
            } catch {
                Log.error("Error reading file")
            }
            Log.info("\(sessionsWithMeasurement)")
        }
    }
    
    func dateFrom(date: Substring, time: Substring) -> Date? {
        let isoDate = String(date + "T" + time)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "MM/dd/yyy'T'HH:mm:ss"
        let date = dateFormatter.date(from:isoDate)
        return date
    }
    
    
}
