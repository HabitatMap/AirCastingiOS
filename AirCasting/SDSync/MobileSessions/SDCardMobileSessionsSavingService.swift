// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreData
import CoreLocation
import Combine
import Resolver

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(fileURL: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void)
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
    
    func saveDataToDb(fileURL: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void) {
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
        
        // We don't want to save data for session which have already been finished.
        // We only want to save measurements of new sessions or for sessions in standalone mode recorded with the syncing device
        var sessionsToCreate: [SessionUUID] = []
        var sessionsToIgnore: [SessionUUID] = []
        
        var i = 0
        let bufferThreshold = 5000
        var savedLines = 0
        var uploadFailed = false
        
        var prevDate: Date?
        
//        measurementStreamStorage.accessStorage { storage in
            do {
                try self.fileLineReader.readLines(of: fileURL, progress: { line in
                    guard !uploadFailed else { return }
                    switch line {
                    case .line(let content):
                        context.perform {
                            let measurementsRow = self.parser.parseMeasurement(lineString: content)
                            Log.info("[SD sync] \(i) - \(savedLines): \(measurementsRow!.sessionUUID) \(measurementsRow!.date)")
                            
                            i += 1
                            guard let measurements = measurementsRow, !sessionsToIgnore.contains(measurements.sessionUUID) else {
                                Log.info("[SD sync Ignoring]")
                                return
                            }
                            
                            if prevDate != nil {
                                if measurementsRow!.date.timeIntervalSince(prevDate!) > 1 {
                                    Log.info("### time difference was: \(measurementsRow!.date.timeIntervalSince(prevDate!))")
                                }
                            }
                            
                            prevDate = measurementsRow!.date
                            
                            var session = self.processedSessions.first(where: { $0.uuid == measurements.sessionUUID })
                            if session == nil {
                                session = self.processSession(sessionUUID: measurements.sessionUUID, deviceID: deviceID, sessionsToIgnore: &sessionsToIgnore, sessionsToCreate: &sessionsToCreate)
                                guard let createdSession = session else { return }
                                self.processedSessions.insert(createdSession)
                            }
                            
                            guard session!.lastMeasurementTime == nil || measurements.date > session!.lastMeasurementTime! else { return }
                            
                            self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements)
                            
                            savedLines += 1
                            guard savedLines == bufferThreshold else { return }
                            
                            do {
                                try self.saveData(streamsWithMeasurements, with: deviceID, sessionsToCreate: &sessionsToCreate)
                                streamsWithMeasurements = [:]
                                savedLines = 0
                            } catch {
                                Log.error("Saving measurements failed")
                                uploadFailed = true
                                return
                            }
                        }
                    case .endOfFile:
                        Log.info("Reached end of csv file")
                    }
                })
                
                context.perform {
                    guard !uploadFailed else {
                        Log.info("##### completion called in line 85")
                        completion(.failure(UploadingError.uploadError))
                        return
                    }
                    
                    do {
                        try self.saveData(streamsWithMeasurements, with: deviceID, sessionsToCreate: &sessionsToCreate)
                        try self.processedSessions.forEach { session in
                            try self.setStatusToFinishedAndUpdateEndTime(for: session.uuid)
                        }
                        try self.context.save()
                        Log.info("##### completion called in line 98")
                        completion(.success(self.processedSessions.map(\.uuid)))
                    } catch {
                        Log.info("##### completion called in line 101")
                        completion(.failure(error))
                    }
                }
            } catch {
                Log.info("##### completion called in line 105")
                completion(.failure(error))
            }
//        }
    }
    
    private func saveData(_ streamsWithMeasurements: [SDStream: [Measurement]], with deviceID: String, sessionsToCreate: inout [SessionUUID]) throws {
        Log.info("[SD Sync] Saving data: \(streamsWithMeasurements.count)")
        try streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
            Log.info("[SD Sync] Saving \(measurements.count) measurements")
            if sessionsToCreate.contains(sdStream.sessionUUID) {
                createSession(sdStream: sdStream, location: measurements.first?.location, time: measurements.first?.time, sessionsToCreate: &sessionsToCreate)
                Log.info("[SD Sync] saving measurements for created session \(sdStream.sessionUUID)")
                saveMeasurements(measurements: measurements, sdStream: sdStream, deviceID: deviceID)
            } else {
                Log.info("[SD Sync] saving measurements for existing session \(sdStream.sessionUUID)")
                saveMeasurements(measurements: measurements, sdStream: sdStream, deviceID: deviceID)
            }
            do {
                Log.info("[SD Sync] Saving context")
                try self.context.save()
            } catch {
                Log.error("[SD Sync] context save failed")
                throw error
            }
        }
    }
    
    private func createSession(sdStream: SDStream, location: CLLocationCoordinate2D?, time: Date?, sessionsToCreate: inout [SessionUUID]) {
        Log.info("[SD Sync] Creating session")
        let session = createSessionInDatabase(Session(uuid: sdStream.sessionUUID, type: .mobile, name: "Imported from SD card", deviceType: .AIRBEAM3, location: location, startTime: time))
        createdSessions.append(session)
        sessionsToCreate.removeAll(where: { $0 == sdStream.sessionUUID })
    }
    
    private func saveMeasurements(measurements: [Measurement], sdStream: SDStream, deviceID: String) {
        Log.info("[SD Sync] Saving measurements")
        do {
            var existingStream = existingMeasurementStream(sdStream.sessionUUID, name: sdStream.name.rawValue)
            if existingStream == nil {
                let measurementStream = createMeasurementStream(for: sdStream.name, sensorPackageName: deviceID)
                existingStream = try saveMeasurementStream(measurementStream, for: sdStream.sessionUUID)
            }
            
            addMeasurements(measurements, toStream: existingStream!)
        } catch {
            Log.info("Saving measurements failed: \(error)")
        }
    }
    
    private func processSession(sessionUUID: SessionUUID, deviceID: String, sessionsToIgnore: inout [SessionUUID], sessionsToCreate: inout [SessionUUID]) -> SDSession? {
        if let existingSession = try? context.existingSession(uuid: sessionUUID) {
            guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                Log.info("[SD SYNC] Ignoring session \(existingSession.name ?? "none")")
                sessionsToIgnore.append(sessionUUID)
                return nil
            }
            
            return SDSession(uuid: sessionUUID, lastMeasurementTime: existingSession.lastMeasurementTime)
        } else {
            sessionsToCreate.append(sessionUUID)
            return SDSession(uuid: sessionUUID, lastMeasurementTime: nil)
        }
    }
    
    private func enqueueForSaving(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]]) {
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .f, header: .f), default: []].append(Measurement(time: measurements.date, value: measurements.f, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .rh, header: .rh), default: []].append(Measurement(time: measurements.date, value: measurements.rh, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm1, header: .pm1), default: []].append(Measurement(time: measurements.date, value: measurements.pm1, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm2_5, header: .pm2_5), default: []].append(Measurement(time: measurements.date, value: measurements.pm2_5, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm10, header: .pm10), default: []].append(Measurement(time: measurements.date, value: measurements.pm10, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
    }
    
    private func createMeasurementStream(for sensorName: MeasurementStreamSensorName, sensorPackageName: String) -> MeasurementStream {
        MeasurementStream(sensorName: sensorName, sensorPackageName: sensorPackageName)
    }
    
    // MARK: - Storage stuff
    
    private func getSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        if let session = createdSessions.first(where: { $0.uuid == sessionUUID}) {
            return session
        }
        
        if let session = try? context.existingSession(uuid: sessionUUID) {
            return session
        }
        
        throw SDSyncMobileDataSavingError.noSession
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
    
    private func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) -> MeasurementStreamEntity? {
        let session = try? context.existingSession(uuid: sessionUUID)
        let stream = session?.streamWith(sensorName: name)
        return stream
    }
    
    enum SDSyncMobileDataSavingError: Error {
        case missingSensorName
        case noSession
    }
    
    private func saveMeasurementStream(_ measurementStream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamEntity {
        return try createMeasurementStream(for: getSession(with: sessionUUID), measurementStream)
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
    
    func addMeasurements(_ measurements: [Measurement], toStream stream: MeasurementStreamEntity) {
        guard let sessionStratTime = stream.session?.startTime else {
            Log.error("No session start time")
            return
        }
        
        guard let lastMeasurementTime = measurements.last?.time else { return }
        
        if lastMeasurementTime.timeIntervalSince(sessionStratTime) >= 60*60*2  {
            
        }
        
        measurements.forEach { measurement in
            let newMeasurement = MeasurementEntity(context: context)
            newMeasurement.location = measurement.location
            newMeasurement.time = measurement.time
            newMeasurement.value = measurement.value
            stream.addToMeasurements(newMeasurement)
        }
    }
    
    private func setStatusToFinishedAndUpdateEndTime(for sessionUUID: SessionUUID) throws {
        let sessionEntity = try getSession(with: sessionUUID)
        sessionEntity.status = .FINISHED
        guard let endTime = sessionEntity.lastMeasurementTime else { return }
        Log.info("SD Sync end time for session \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
        sessionEntity.endTime = endTime
    }
    
    private func averageMeasurements(_ measurements: [Measurement]) {
        
    }
}
