// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreLocation


struct SDSession: Hashable {
    let uuid: SessionUUID
    let lastMeasurementTime: Date?
}

struct SDStream: Hashable {
    let sessionUUID: SessionUUID
    let name: StreamSensorName
}

enum StreamSensorName: String {
    case f = "AirBeam3-F"
    case rh = "AirBeam3-RH"
    case pm1 = "AirBeam3-PM1"
    case pm2_5 = "AirBeam3-PM2.5"
    case pm10 = "AirBeam3-PM10"
}

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(fileURL: URL, deviceID: String)
}

struct SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    private let fileLineReader = DefaultFileLineReader()
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func saveDataToDb(fileURL: URL, deviceID: String) {
        var sessionsWithTimes = Set<SDSession>()
        var sessionsWithMeasurement: [SDStream: [Measurement]] = [:]
        
        // We don't want to save data for session which have already been finished.
        // We only want to save measurements of new sessions or for sessions in standalone mode
        var sessionsToCreate: [SessionUUID] = []
        var sessionsToIgnore: [SessionUUID] = []
        
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
                            let rh = Double(measurementInfo[9]),
                            let pm1 = Double(measurementInfo[10]),
                            let pm2_5 = Double(measurementInfo[11]),
                            let pm10 = Double(measurementInfo[12])
                        else {
                            Log.info("Wrong data format in the csv row: \(line)")
                            return
                        }
                        guard !sessionsToIgnore.contains(sessionUUID) else { return }
                        
                        var session = sessionsWithTimes.first(where: {$0.uuid == sessionUUID })
                        
                        if session == nil {
                            do {
                                if let existingSession = try storage.getExistingSession(with: sessionUUID) {
                                    //TODO: check if session was recorded with the syncing AB
                                    guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                                        Log.info("## Ignoring session \(existingSession.name)")
                                        sessionsToIgnore.append(sessionUUID)
                                        return
                                    }
                                    
                                    session = SDSession(uuid: sessionUUID, lastMeasurementTime: existingSession.lastMeasurementTime)
                                } else {
                                    session = SDSession(uuid: sessionUUID, lastMeasurementTime: nil)
                                    sessionsToCreate.append(sessionUUID)
                                }
                            } catch {
                                Log.error(error.localizedDescription)
                            }
                            
                            sessionsWithTimes.insert(session!)
                        }
                        
                        if  session!.lastMeasurementTime == nil || date > session!.lastMeasurementTime! {
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .f), default: []].append(Measurement(time: date, value: f, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .rh), default: []].append(Measurement(time: date, value: rh, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .pm1), default: []].append(Measurement(time: date, value: pm1, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .pm2_5), default: []].append(Measurement(time: date, value: pm2_5, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                            sessionsWithMeasurement[SDStream(sessionUUID: sessionUUID, name: .pm10), default: []].append(Measurement(time: date, value: pm10, location: CLLocationCoordinate2D(latitude: lat, longitude: long)))
                        }
                    case .endOfFile:
                        Log.info("Reached end of csv file")
                    }
                })
                
                try sessionsWithMeasurement.forEach { (sdStream: SDStream, measurements: [Measurement]) in
                    Log.info("## \(sdStream): \(measurements)")
                    if sessionsToCreate.contains(sdStream.sessionUUID) {
                        do {
                            try storage.createSession(Session(uuid: sdStream.sessionUUID, type: .mobile, name: "Imported from SD card", deviceType: .AIRBEAM3, location: measurements.first?.location, startTime: measurements.first?.time))
                            Log.info("## Created new session")
                        } catch {
                            Log.error("Coudn't create a new session from imported data: \(error.localizedDescription)")
                        }
                        sessionsToCreate.removeAll(where: {$0 == sdStream.sessionUUID })
                        let measurementStream = createMeasurementStream(for: sdStream.name, sensorPackageName: deviceID)
                        let streamID = try storage.createMeasurementStream(measurementStream, for: sdStream.sessionUUID)
                        try storage.addMeasurements(measurements, toStreamWithID: streamID)
                    } else {
                        do {
                            var existingStreamID = try storage.existingMeasurementStream(sdStream.sessionUUID, name: sdStream.name.rawValue)
                            if existingStreamID == nil {
                                let measurementStream = createMeasurementStream(for: sdStream.name, sensorPackageName: deviceID)
                                existingStreamID = try storage.createMeasurementStream(measurementStream, for: sdStream.sessionUUID)
                            }

                            try storage.addMeasurements(measurements, toStreamWithID: existingStreamID!)
                            try storage.setStatusToFinishedAndUpdateEndTime(for: sdStream.sessionUUID, endTime: measurements.last?.time)
                        } catch {
                            Log.info("\(error)")
                        }
                    }
                }
            } catch {
                Log.error("Error reading file")
            }
        }
    }
    
    func dateFrom(date: Substring, time: Substring) -> Date? {
        let isoDate = String(date + "T" + time)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MM/dd/yyy'T'HH:mm:ss"
        let date = dateFormatter.date(from:isoDate)
        return date?.currentUTCTimeZoneDate
    }
    
    func createMeasurementStream(for sensorName: StreamSensorName, sensorPackageName: String) -> MeasurementStream {
        switch sensorName {
        case .f:
            return MeasurementStream(id: nil,
                              sensorName: sensorName.rawValue,
                              sensorPackageName: sensorPackageName, // CHANGE
                              measurementType: "Temperature",
                              measurementShortType: "F",
                              unitName: "degrees Fahrenheit",
                              unitSymbol: "F",
                              thresholdVeryHigh: 135,
                              thresholdHigh: 100,
                              thresholdMedium: 75,
                              thresholdLow: 45,
                              thresholdVeryLow: 15)
        case .rh:
            return MeasurementStream(id: nil,
                              sensorName: sensorName.rawValue,
                              sensorPackageName: sensorPackageName, // CHANGE
                              measurementType: "Humidity",
                              measurementShortType: "RH",
                              unitName: "percent",
                              unitSymbol: "%",
                              thresholdVeryHigh: 100,
                              thresholdHigh: 75,
                              thresholdMedium: 50,
                              thresholdLow: 25,
                              thresholdVeryLow: 0)
        case .pm1:
            return MeasurementStream(id: nil,
                              sensorName: sensorName.rawValue,
                              sensorPackageName: sensorPackageName, // CHANGE
                              measurementType: "Particulate Matter",
                              measurementShortType: "PM",
                              unitName: "micrograms per cubic meter",
                              unitSymbol: "µg/m³",
                              thresholdVeryHigh: 150,
                              thresholdHigh: 55,
                              thresholdMedium: 35,
                              thresholdLow: 12,
                              thresholdVeryLow: 0)
        case .pm2_5:
            return MeasurementStream(id: nil,
                              sensorName: sensorName.rawValue,
                              sensorPackageName: sensorPackageName, // CHANGE
                              measurementType: "Particulate Matter",
                              measurementShortType: "PM",
                              unitName: "micrograms per cubic meter",
                              unitSymbol: "µg/m³",
                              thresholdVeryHigh: 150,
                              thresholdHigh: 55,
                              thresholdMedium: 35,
                              thresholdLow: 12,
                              thresholdVeryLow: 0)
        case .pm10:
            return MeasurementStream(id: nil,
                              sensorName: sensorName.rawValue,
                              sensorPackageName: sensorPackageName, // CHANGE
                              measurementType: "Particulate Matter",
                              measurementShortType: "PM",
                              unitName: "micrograms per cubic meter",
                              unitSymbol: "µg/m³",
                              thresholdVeryHigh: 200,
                              thresholdHigh: 100,
                              thresholdMedium: 50,
                              thresholdLow: 20,
                              thresholdVeryLow: 0)
        }
    }
}
