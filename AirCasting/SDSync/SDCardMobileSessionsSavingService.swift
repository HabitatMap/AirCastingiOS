// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreLocation
import Combine

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(fileURL: URL, deviceID: String)
}

class SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    private let fileLineReader: FileLineReader
    private let measurementStreamStorage: MeasurementStreamStorage
    private let parser = SDCardMeasurementsParser()
    
    init(measurementStreamStorage: MeasurementStreamStorage, fileLineReader: FileLineReader) {
        self.measurementStreamStorage = measurementStreamStorage
        self.fileLineReader = fileLineReader
    }
    
    func saveDataToDb(fileURL: URL, deviceID: String) {
        var processedSessions = Set<SDSession>()
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
        
        // We don't want to save data for session which have already been finished.
        // We only want to save measurements of new sessions or for sessions in standalone mode
        var sessionsToCreate: [SessionUUID] = []
        var sessionsToIgnore: [SessionUUID] = []
        
        measurementStreamStorage.accessStorage { storage in
            var fileReadingCancellable: AnyCancellable?
            fileReadingCancellable = self.read(fileURL: fileURL).sink { [weak self] completion in
                defer { fileReadingCancellable?.cancel() }
                guard case .finished = completion else { return }
                self?.saveData(streamsWithMeasurements, to: storage, with: deviceID, sessionsToCreate: &sessionsToCreate)
            } receiveValue: { [weak self] measurements in
                guard let self = self, let measurements = measurements, !sessionsToIgnore.contains(measurements.sessionUUID) else { return }
                
                var session = processedSessions.first(where: {$0.uuid == measurements.sessionUUID })
                if session == nil {
                    session = self.processSession(storage: storage, sessionUUID: measurements.sessionUUID, deviceID: deviceID, sessionsToIgnore: &sessionsToIgnore, sessionsToCreate: &sessionsToCreate)
                    guard session != nil else { return }
                    processedSessions.insert(session!)
                }
                
                guard session!.lastMeasurementTime == nil || measurements.date > session!.lastMeasurementTime! else { return }
                
                self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements)
            }
        }
    }
    
    private func read(fileURL: URL) -> PassthroughSubject<SDCardMeasurementsRow?, Error> {
        let publisher = PassthroughSubject<SDCardMeasurementsRow?, Error>()
        do {
            try fileLineReader.readLines(of: fileURL, progress: { line in
                switch line {
                case .line(let content):
                    let measurementsRow = parser.parseMeasurement(lineSting: content)
                    publisher.send(measurementsRow)
                case .endOfFile:
                    publisher.send(completion: .finished)
                }
            })
        } catch {
            Log.error("Cannot read file \(fileURL): \(error.localizedDescription)")
            publisher.send(completion: .failure(error))
        }
        return publisher
    }
    
    private func saveData(_ streamsWithMeasurements: [SDStream: [Measurement]], to storage: HiddenCoreDataMeasurementStreamStorage, with deviceID: String, sessionsToCreate: inout [SessionUUID]) {
        streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
            Log.info("## \(sdStream): \(measurements)")
            if sessionsToCreate.contains(sdStream.sessionUUID) {
                createSession(storage: storage, sdStream: sdStream, location: measurements.first?.location, time: measurements.first?.time, sessionsToCreate: &sessionsToCreate)
                saveMeasurements(measurements: measurements, storage: storage, sdStream: sdStream, deviceID: deviceID)
            } else {
                saveMeasurements(measurements: measurements, storage: storage, sdStream: sdStream, deviceID: deviceID)
                do {
                    try storage.setStatusToFinishedAndUpdateEndTime(for: sdStream.sessionUUID, endTime: measurements.last?.time)
                } catch {
                    Log.info("Error setting status to finished and updating end time: \(error)")
                }
            }
        }
    }
    
    private func createSession(storage: HiddenCoreDataMeasurementStreamStorage, sdStream: SDStream, location: CLLocationCoordinate2D?, time: Date?, sessionsToCreate: inout [SessionUUID]) {
        do {
            try storage.createSession(Session(uuid: sdStream.sessionUUID, type: .mobile, name: "Imported from SD card", deviceType: .AIRBEAM3, location: location, startTime: time))
            sessionsToCreate.removeAll(where: {$0 == sdStream.sessionUUID })
        } catch {
            Log.error("Couldn't create session: \(error.localizedDescription)")
        }
    }
    
    private func saveMeasurements(measurements: [Measurement], storage: HiddenCoreDataMeasurementStreamStorage, sdStream: SDStream, deviceID: String) {
        do {
            var existingStreamID = try storage.existingMeasurementStream(sdStream.sessionUUID, name: sdStream.name.rawValue)
            if existingStreamID == nil {
                let measurementStream = createMeasurementStream(for: sdStream.name, sensorPackageName: deviceID)
                existingStreamID = try storage.saveMeasurementStream(measurementStream, for: sdStream.sessionUUID)
            }
            try storage.addMeasurements(measurements, toStreamWithID: existingStreamID!)
        } catch {
            Log.info("Saving measurements failed: \(error)")
        }
    }
    
    private func processSession(storage: HiddenCoreDataMeasurementStreamStorage, sessionUUID: SessionUUID, deviceID: String, sessionsToIgnore: inout [SessionUUID], sessionsToCreate: inout [SessionUUID]) -> SDSession? {
        do {
            if let existingSession = try storage.getExistingSession(with: sessionUUID) {
                guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                    Log.info("## Ignoring session \(existingSession.name ?? "none")")
                    sessionsToIgnore.append(sessionUUID)
                    return nil
                }
                
                return SDSession(uuid: sessionUUID, lastMeasurementTime: existingSession.lastMeasurementTime)
            } else {
                sessionsToCreate.append(sessionUUID)
                return SDSession(uuid: sessionUUID, lastMeasurementTime: nil)
            }
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    private func enqueueForSaving(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]]) {
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .f), default: []].append(Measurement(time: measurements.date, value: measurements.f, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .rh), default: []].append(Measurement(time: measurements.date, value: measurements.rh, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm1), default: []].append(Measurement(time: measurements.date, value: measurements.pm1, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm2_5), default: []].append(Measurement(time: measurements.date, value: measurements.pm2_5, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm10), default: []].append(Measurement(time: measurements.date, value: measurements.pm10, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
    }
    
    private func createMeasurementStream(for sensorName: StreamSensorName, sensorPackageName: String) -> MeasurementStream {
        switch sensorName {
        case .f:
            return MeasurementStream(id: nil,
                              sensorName: sensorName.rawValue,
                              sensorPackageName: sensorPackageName,
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
                              sensorPackageName: sensorPackageName,
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
                              sensorPackageName: sensorPackageName,
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
                              sensorPackageName: sensorPackageName,
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
                              sensorPackageName: sensorPackageName,
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

fileprivate struct SDSession: Hashable {
    let uuid: SessionUUID
    let lastMeasurementTime: Date?
}

fileprivate struct SDStream: Hashable {
    let sessionUUID: SessionUUID
    let name: StreamSensorName
}

fileprivate enum StreamSensorName: String {
    case f = "AirBeam3-F"
    case rh = "AirBeam3-RH"
    case pm1 = "AirBeam3-PM1"
    case pm2_5 = "AirBeam3-PM2.5"
    case pm10 = "AirBeam3-PM10"
}
