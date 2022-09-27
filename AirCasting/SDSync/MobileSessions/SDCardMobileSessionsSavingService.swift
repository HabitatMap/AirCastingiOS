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
    case noLastMeasurementTime
}

struct SDSession2: Hashable {
    let uuid: SessionUUID
    var startTime: Date?
    var lastMeasurementTime: Date?
    var needsToBeCreated: Bool
    var averaging: AveragingWindow?
}

protocol AverageableMeasurement {
    var time: Date! { get }
}

extension MeasurementEntity: AverageableMeasurement { }

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
                var error: Error?
                let group = DispatchGroup()
                for file in files {
                    group.enter()
                    saveDataToDb(fileURL: file, deviceID: deviceID) { result in
                        switch result {
                        case .success():
                            Log.info("Successfully saved session: \(file.path.split(separator: "/").last ?? "na")")
                            group.leave()
                        case .failure(let failureError):
                            Log.info("## Failure for session: \(file.path.split(separator: "/").last ?? "na")")
                            error = failureError
                            group.leave()
                            return
                        }
                    }
                }
                group.notify(queue: DispatchQueue.global()) {
                    error != nil ? completion(.failure(error!)) : completion(.success(()))
                }
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
        
        guard let lastLineInFile = try? fileLineReader.readLastNonEmptyLine(of: fileURL) else {
            Log.error("Failed to get last line from file for session \(session.uuid)")
            completion(.failure(SDMobileSavingErrors.noLastMeasurementTime))
            return
        }
        
        Log.info("## LAST LINE: \(lastLineInFile)")
        
        guard let lastMeasurementTime = parser.getMeasurementTime(lineString: lastLineInFile) else {
            Log.error("Failed to read last measurement time from file")
            completion(.failure(SDMobileSavingErrors.noLastMeasurementTime))
            return
        }
        
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
                        
                        if sessionData.averaging == nil {
                            sessionData.averaging = self.calculateAveragingWindow(startTime: sessionData.startTime ?? measurements.date, lastMeasurement: lastMeasurementTime)
                            Log.info("## Set averaging window to \(sessionData.averaging)")
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
                    Log.info("Reached end of csv file for session \(sessionData.uuid)")
                }
            })
            
            context.perform {
                guard !savingFailed else {
                    Log.info("##### completion called in line 85")
                    completion(.failure(UploadingError.uploadError))
                    return
                }
                
                do {
                    try self.saveData(streamsWithMeasurements, session: &sessionData)
                    try self.averageUnaveragedMeasurements(sessionUUID: sessionData.uuid, averagingWindow: sessionData.averaging ?? .zeroWindow)
                    try self.setStatusToFinishedAndUpdateEndTime(for: sessionData.uuid)
                    try self.context.save()
                    Log.info("##### completion called in line 98")
                    completion(.success(()))
                } catch {
                    Log.info("##### completion called in line 101")
                    completion(.failure(error))
                }
            }
        } catch {
            // ERRORR
        }
    }
    
    private func calculateAveragingWindow(startTime: Date, lastMeasurement: Date) -> AveragingWindow {
        let sessionDuration = abs(lastMeasurement.timeIntervalSince(startTime))
        if sessionDuration <= TimeInterval(TimeThreshold.firstThreshold.rawValue) {
            return .zeroWindow
        } else if sessionDuration <= TimeInterval(TimeThreshold.secondThreshold.rawValue) {
            return .firstThresholdWindow
        }
        return .secondThresholdWindow
    }
    
    private func processSession(sessionUUID: SessionUUID, deviceID: String) -> SDSession2? {
        var session: SDSession2? = nil
        context.performAndWait {
            if let existingSession = try? context.existingSession(uuid: sessionUUID) {
                guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                    Log.info("[SD SYNC] Ignoring session \(existingSession.name ?? "none")")
                    return
                }
                
                session = SDSession2(uuid: sessionUUID, startTime: existingSession.startTime, lastMeasurementTime: existingSession.lastMeasurementTime, needsToBeCreated: false)
            } else {
                session = SDSession2(uuid: sessionUUID, needsToBeCreated: true)
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
                try createStreamWithMeasurements(stream: sdStream, measurements: measurements, session: sessionEntity, averagingWindow: session.averaging ?? .zeroWindow)
            }
            session.needsToBeCreated = false
        } else {
            Log.info("## saving measurements for existing session")
            try streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
                Log.info("## saving measurements for \(sdStream.name)")
                try saveMeasurementsToStream(measurements: measurements, sdStream: sdStream, averagingWindow: session.averaging ?? .zeroWindow)
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
    
    private func createStreamWithMeasurements(stream: SDStream, measurements: [Measurement], session: SessionEntity, averagingWindow: AveragingWindow) throws {
        let measurementStream = MeasurementStream(sensorName: stream.name, sensorPackageName: stream.deviceID)
        let streamEntity = try createMeasurementStream(for: session, measurementStream)
        addMeasurements(measurements, toStream: streamEntity, averaging: averagingWindow)
    }
    
    private func createSessionInDatabase(_ session: Session) -> SessionEntity {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return sessionEntity
    }
    
    private func saveMeasurementsToStream(measurements: [Measurement], sdStream: SDStream, averagingWindow: AveragingWindow) throws {
        Log.info("[SD Sync] Saving measurements")
            let session = try context.existingSession(uuid: sdStream.sessionUUID)
            var existingStream = session.streamWith(sensorName: sdStream.name.rawValue)
            if existingStream == nil {
                let measurementStream = MeasurementStream(sensorName: sdStream.name, sensorPackageName: sdStream.deviceID)
                existingStream = try createMeasurementStream(for: session, measurementStream)
            }
            
        addMeasurements(measurements, toStream: existingStream!, averaging: averagingWindow) // CHANGE THIS
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
    
    private func addMeasurements(_ measurements: [Measurement], toStream stream: MeasurementStreamEntity, averaging: AveragingWindow) {
        Log.info("####### SAVING MEASUREMENTS WITH AVERAGING")
        guard averaging != .zeroWindow else {
            measurements.forEach( { addMeasurement(to: stream, measurement: $0, averagingWindow: .zeroWindow) })
            return
        }
        
        guard let sessionStartTime = stream.session?.startTime else {
            Log.error("No session start time!")
            return
        }
        
        guard let firstMeasurementTime = measurements.first?.time else {
            Log.info("No measurements")
            return
        }
        
        let secondsFromTheStartOfLastAveragingWindow = Int(firstMeasurementTime.timeIntervalSince(sessionStartTime)) % averaging.rawValue
        
        var intervalStart: Date
        
        intervalStart = firstMeasurementTime.addingTimeInterval(TimeInterval(averaging.rawValue - secondsFromTheStartOfLastAveragingWindow))
        
        var intervalEnd = intervalStart.addingTimeInterval(TimeInterval(averaging.rawValue))
        Log.info("## session start: \(sessionStartTime)\n measurement time: \(firstMeasurementTime)\n \(intervalStart) - \(intervalEnd)")
        
        var measurementsBuffer = [Measurement]()
        
        measurements.forEach { measurement in
            guard measurement.time >= intervalStart else {
                // We are skipping those measurements that don't fit to a full averaging window to deal with them later together with the rest of unaveraged measurements of this session
                addMeasurement(to: stream, measurement: measurement, averagingWindow: .zeroWindow)
                return
            }
            
            guard measurement.time < intervalEnd else {
                Log.info("## AVERAGING \(measurementsBuffer.count): \(measurementsBuffer.first?.time) - \(measurementsBuffer.last?.time)")
                guard let newMeasurement = averageMeasurements(measurementsBuffer, time: intervalEnd) else { return }
                addMeasurement(to: stream, measurement: newMeasurement, averagingWindow: averaging)
                
                
                while measurement.time >= intervalEnd {
                    Log.info("## \(measurement.time), interval end: \(intervalEnd) NEXT INTERVAL")
                    intervalStart = intervalEnd
                    intervalEnd = intervalEnd.addingTimeInterval(TimeInterval(averaging.rawValue))
                }
                Log.info("## \(measurement.time), interval end: \(intervalEnd) APPENDING")
                measurementsBuffer = [measurement]
                return
            }
            
            measurementsBuffer.append(measurement)
        }
        
        Log.info("## SAVING REST: \(measurementsBuffer.first) - \(measurementsBuffer.last)")
        measurementsBuffer.forEach({ addMeasurement(to: stream, measurement: $0, averagingWindow: .zeroWindow) })
    }
    
    private func addMeasurement(to stream: MeasurementStreamEntity, measurement: Measurement, averagingWindow: AveragingWindow) {
        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        newMeasurement.averagingWindow = averagingWindow.rawValue
        stream.addToMeasurements(newMeasurement)
    }
    
    private func averageMeasurements(_ measurements: [Measurement], time: Date) -> Measurement? {
        guard !measurements.isEmpty else { return nil }
        let average = measurements.map({ $0.value }).reduce(0.0, +) / Double(measurements.count)
        let middleIndex = measurements.count/2
        Log.info("## middle index \(middleIndex)")
        let middleMeasurement = measurements[middleIndex]
        return Measurement(time: time, value: average, location: middleMeasurement.location)
    }
    
    private func averageMeasurements(_ measurements: [MeasurementEntity], time: Date) -> MeasurementEntity? {
        guard !measurements.isEmpty else { return nil }
        let average = measurements.map({ $0.value }).reduce(0.0, +) / Double(measurements.count)
        let middleIndex = measurements.count/2
        let middleMeasurement = measurements[middleIndex]
        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.time = time
        newMeasurement.location = middleMeasurement.location
        newMeasurement.value = average
        Log.info("## averaged to \(newMeasurement)")
        return newMeasurement
    }

    private func setStatusToFinishedAndUpdateEndTime(for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = .FINISHED
        guard let endTime = sessionEntity.lastMeasurementTime else { return }
        Log.info("## SD Sync end time for session \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
        sessionEntity.endTime = endTime
    }
    
    private func averageUnaveragedMeasurements(sessionUUID: SessionUUID, averagingWindow: AveragingWindow) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        try sessionEntity.allStreams.forEach({
            try averageUnaveragedMeasurements(stream: $0, averagingWindow: averagingWindow)
            try orderAllMeasurements(stream: $0)
        })
    }
    
    private func averageUnaveragedMeasurements(stream: MeasurementStreamEntity, averagingWindow: AveragingWindow) throws {
        Log.info("#### Averaging unaveraged measurements for stream \(stream.sensorName)")
        guard averagingWindow != .zeroWindow else {
            return
        }
        
        let fetchRequest = MeasurementEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "averagingWindow != %d AND measurementStream == %@", averagingWindow.rawValue, stream)
        let measurements = try context.fetch(fetchRequest)
        Log.debug("## measurements: \(measurements)")
        
        guard let sessionStartTime = stream.session?.startTime else {
            Log.error("No session start time!")
            return
        }
        
        guard let firstMeasurementTime = measurements.first?.time else {
            Log.info("No measurements")
            return
        }
        
        var intervalStart = sessionStartTime
        var intervalEnd = intervalStart.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
        Log.info("## session start: \(sessionStartTime)\n measurement time: \(firstMeasurementTime)\n \(intervalStart) - \(intervalEnd)")
        
        var measurementsBuffer = [MeasurementEntity]()
        
        try measurements.forEach { measurement in
            guard measurement.time >= intervalStart else {
                Log.error("## \(measurement.time) WRONG STARTING TIME \(intervalStart)")
                // This shouldn't happen
                return
            }
            
            guard measurement.time < intervalEnd else {
                Log.info("## AVERAGING \(measurementsBuffer.count): \(measurementsBuffer.first?.time) - \(measurementsBuffer.last?.time)")
                guard let newMeasurement = averageMeasurements(measurementsBuffer, time: intervalEnd) else {
                    return
                }
                
                measurementsBuffer.forEach(context.delete(_:))
                newMeasurement.averagingWindow = averagingWindow.rawValue
                stream.addToMeasurements(newMeasurement)
                try context.save()
                
                while measurement.time >= intervalEnd {
                    Log.info("## \(measurement.time), interval end: \(intervalEnd) NEXT INTERVAL")
                    intervalStart = intervalEnd
                    intervalEnd = intervalEnd.addingTimeInterval(TimeInterval(averagingWindow.rawValue))
                }
                Log.info("## \(measurement.time), interval end: \(intervalEnd) APPENDING")
                measurementsBuffer = [measurement]
                return
            }
            Log.debug("## Buffer count is \(measurementsBuffer.count) appending measurement \(measurement.time)")
            measurementsBuffer.append(measurement)
        }
        
        Log.info("## REMOVING: \(measurementsBuffer)")
        measurementsBuffer.forEach(context.delete(_:))
        try context.save()
    }
    
    private func orderAllMeasurements(stream: MeasurementStreamEntity) throws {
        let fetchRequest = MeasurementEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "measurementStream == %@", stream)
        let measurements = try context.fetch(fetchRequest)
        stream.measurements = NSOrderedSet(array: measurements)
        try context.save()
    }
}
