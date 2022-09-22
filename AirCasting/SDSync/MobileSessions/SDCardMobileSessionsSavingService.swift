// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreData
import CoreLocation
import Combine
import Resolver

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(filesDirectoryURL: URL, deviceID: String, completion: @escaping (Result<Void, Error>) -> Void)
}

enum SDMobileSavingErrors: Error {
    case noUUID
}

struct SDSession2: Hashable {
    let uuid: SessionUUID
    var startTime: Date?
    var lastMeasurementTime: Date?
    var needsToBeCreated: Bool
    var needsToBeAveraged: Bool
}

class SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    @Injected private var fileLineReader: FileLineReader
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var persistenceController: PersistenceController
    @Injected private var updateSessionParamsService: UpdateSessionParamsService
    private let parser = SDCardMeasurementsParser()
    
    private lazy var context: NSManagedObjectContext = persistenceController.createContext()
    
    var createdSessions: [SessionEntity] = []
    var processedSessions = Set<SDSession>()
    
    func saveDataToDb(filesDirectoryURL: URL, deviceID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filesDirectoryURL.path, isDirectory: &isDirectory) else { completion(.success(())); return }
        
        if !isDirectory.boolValue {
            saveDataToDb(fileURL: filesDirectoryURL, deviceID: deviceID, completion: completion)
        } else {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: filesDirectoryURL.path).compactMap({ filesDirectoryURL.path + "/" + $0 }).compactMap(URL.init(string:))
                Log.info("Files: \(files)")
                
                for file in files {
                    saveDataToDb(fileURL: file, deviceID: deviceID) { result in
                        switch result {
                        case .success():
                            Log.info("Successfully saved session: \(file.path.split(separator: "/").last ?? "na")")
                        case .failure(let error):
                            Log.info("## Failure for session: \(file.path.split(separator: "/").last ?? "na")")
                            completion(.failure(error))
                            return
                        }
                    }
                }
                Log.info("## Success")
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func saveDataToDb(fileURL: URL, deviceID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionUUIDString = fileURL.path.split(separator: "/").last else {
            completion(.failure(SDMobileSavingErrors.noUUID))
            return
        }
        
        let sessionUUID = SessionUUID(stringLiteral: String(sessionUUIDString))
        
        Log.info("## Processing mobile session: \(sessionUUID)")
        
        guard let processedSession = processSession(sessionUUID: sessionUUID, deviceID: deviceID) else {
            Log.info("## Ignoring session \(sessionUUID). Moving forward.")
            completion(.success(()))
            return
        }
        
        
        Log.info("## processed session: \(processedSession)")
        
        processFile(fileURL: fileURL, session: processedSession, deviceID: deviceID, completion: completion)
    }
    
    private func processFile(fileURL: URL, session: SDSession2, deviceID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
        var i = 0
        let bufferThreshold = 5000
        var savedLines = 0
        var savingFailed = false
        
        var sessionData = session
        
        do {
            try self.fileLineReader.readLines(of: fileURL, progress: { line in
                guard !savingFailed else { return }
                switch line {
                case .line(let content):
                    context.perform {
                        guard let measurements = self.parser.parseMeasurement(lineString: content) else {
                            Log.error("## Failed to parse content: \(content)")
                            return
                        }
                        
                        Log.info("[SD sync] \(i) - \(savedLines): \(measurements.date)")
                        
                        i += 1
                        
                        guard sessionData.lastMeasurementTime == nil || measurements.date > sessionData.lastMeasurementTime! else {
                            Log.info("## Ignoring measurement")
                            return
                        }
                        
                        self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements, deviceID: deviceID)
                        
                        savedLines += 1
                        guard savedLines == bufferThreshold else { return }
                        
                        do {
                            Log.info("## Threshold exceeded, saving data")
                            try self.saveData(streamsWithMeasurements, session: &sessionData)
                            streamsWithMeasurements = [:]
                            savedLines = 0
                        } catch {
                            Log.error("Saving measurements failed")
                            savingFailed = true
                            return
                        }
                    }
                case .endOfFile:
                    Log.info("Reached end of csv file")
                }
                
                context.perform {
                    guard !savingFailed else {
                        Log.info("##### completion called in line 85")
                        completion(.failure(UploadingError.uploadError))
                        return
                    }
                    
                    do {
                        try self.saveData(streamsWithMeasurements, session: &sessionData)
                        try self.setStatusToFinishedAndUpdateEndTime(for: sessionData.uuid)
                        try self.context.save()
                        Log.info("##### completion called in line 98")
                        completion(.success(()))
                    } catch {
                        Log.info("##### completion called in line 101")
                        completion(.failure(error))
                    }
                }
            })
        } catch {
            // ERRORR
        }
    }
    
    private func processSession(sessionUUID: SessionUUID, deviceID: String) -> SDSession2? {
        var session: SDSession2? = nil
        context.performAndWait {
            if let existingSession = try? context.existingSession(uuid: sessionUUID) {
                guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                    Log.info("[SD SYNC] Ignoring session \(existingSession.name ?? "none")")
                    return
                }
                // TODO: check if it should be averaged
                session = SDSession2(uuid: sessionUUID, startTime: existingSession.startTime, lastMeasurementTime: existingSession.lastMeasurementTime, needsToBeCreated: false, needsToBeAveraged: false)
            } else {
                session = SDSession2(uuid: sessionUUID, needsToBeCreated: true, needsToBeAveraged: false)
            }
        }
        return session
    }
    
    private func enqueueForSaving(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]], deviceID: String) {
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .f, header: .f), default: []].append(Measurement(time: measurements.date, value: measurements.f, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .rh, header: .rh), default: []].append(Measurement(time: measurements.date, value: measurements.rh, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .pm1, header: .pm1), default: []].append(Measurement(time: measurements.date, value: measurements.pm1, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .pm2_5, header: .pm2_5), default: []].append(Measurement(time: measurements.date, value: measurements.pm2_5, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .pm10, header: .pm10), default: []].append(Measurement(time: measurements.date, value: measurements.pm10, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
    }
    
    
    private func saveData(_ streamsWithMeasurements: [SDStream: [Measurement]], session: inout SDSession2) throws {
        Log.info("[SD Sync] Saving data: \(streamsWithMeasurements.count)")
        if session.needsToBeCreated {
            let sessionEntity = createSession(uuid: session.uuid, location: streamsWithMeasurements.values.first?.first?.location, time: streamsWithMeasurements.values.first?.first?.time)
            Log.info("[SD Sync] saving measurements for created session")
            try streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
                try createStreamWithMeasurements(stream: sdStream, measurements: measurements, session: sessionEntity)
            }
            session.needsToBeCreated = false
        } else {
            Log.info("## saving measurements for existing session")
            try streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
                Log.info("## saving measurements for \(sdStream.name)")
                try saveMeasurementsToStream(measurements: measurements, sdStream: sdStream)
            }
        }
        
        do {
            Log.info("[SD Sync] Saving context")
            try self.context.save()
        } catch {
            Log.error("[SD Sync] context save failed")
            throw error
        }
    }
    
    private func createSession(uuid: SessionUUID, location: CLLocationCoordinate2D?, time: Date?) -> SessionEntity {
        Log.info("[SD Sync] Creating session: \(uuid)")
        return createSessionInDatabase(Session(uuid: uuid, type: .mobile, name: "Imported from SD card", deviceType: .AIRBEAM3, location: location, startTime: time))
    }
    
    private func createStreamWithMeasurements(stream: SDStream, measurements: [Measurement], session: SessionEntity) throws {
        let measurementStream = MeasurementStream(sensorName: stream.name, sensorPackageName: stream.deviceID)
        let streamEntity = try createMeasurementStream(for: session, measurementStream)
        addMeasurements(measurements, toStream: streamEntity)
    }
    
    private func createSessionInDatabase(_ session: Session) -> SessionEntity {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return sessionEntity
    }
    
    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
    
    enum SDSyncMobileDataSavingError: Error {
            case missingSensorName
            case noSession
        }
    
    private func createMeasurementStream(for session: SessionEntity, _ stream: MeasurementStream) throws -> MeasurementStreamEntity {
        guard let sensorName = stream.sensorName else {
            throw SDSyncMobileDataSavingError.missingSensorName
        }
        
        let newStream = MeasurementStreamEntity(context: context)
        newStream.sensorName = stream.sensorName
        newStream.sensorPackageName = stream.sensorPackageName
        newStream.measurementType = stream.measurementType
        newStream.measurementShortType = stream.measurementShortType
        newStream.unitName = stream.unitName
        newStream.unitSymbol = stream.unitSymbol
        newStream.thresholdVeryLow = stream.thresholdVeryLow
        newStream.thresholdLow = stream.thresholdLow
        newStream.thresholdMedium = stream.thresholdMedium
        newStream.thresholdHigh = stream.thresholdHigh
        newStream.thresholdVeryHigh = stream.thresholdVeryHigh
        newStream.gotDeleted = false
        
        session.addToMeasurementStreams(newStream)
        
        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
            threshold.thresholdVeryLow = stream.thresholdVeryLow
            threshold.thresholdLow = stream.thresholdLow
            threshold.thresholdMedium = stream.thresholdMedium
            threshold.thresholdHigh = stream.thresholdHigh
            threshold.thresholdVeryHigh = stream.thresholdVeryHigh
        }
        
        return newStream
    }
    
    private func addMeasurements(_ measurements: [Measurement], toStream stream: MeasurementStreamEntity) {
        measurements.forEach { measurement in
            let newMeasurement = MeasurementEntity(context: context)
            newMeasurement.location = measurement.location
            newMeasurement.time = measurement.time
            newMeasurement.value = measurement.value
            stream.addToMeasurements(newMeasurement)
        }
    }
    
    private func saveMeasurementsToStream(measurements: [Measurement], sdStream: SDStream) throws {
        Log.info("[SD Sync] Saving measurements")
            let session = try context.existingSession(uuid: sdStream.sessionUUID)
            var existingStream = session.streamWith(sensorName: sdStream.name.rawValue)
            if existingStream == nil {
                let measurementStream = MeasurementStream(sensorName: sdStream.name, sensorPackageName: sdStream.deviceID)
                existingStream = try createMeasurementStream(for: session, measurementStream)
            }
            
            addMeasurements(measurements, toStream: existingStream!)
    }

    private func setStatusToFinishedAndUpdateEndTime(for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = .FINISHED
        guard let endTime = sessionEntity.lastMeasurementTime else { return }
        Log.info("## SD Sync end time for session \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
        sessionEntity.endTime = endTime
    }
}
