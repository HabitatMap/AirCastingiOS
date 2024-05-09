// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreData
import CoreLocation
import Combine
import Resolver

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(filesDirectoryURL: URL, deviceID: String, deviceLocation: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void)
}

enum SDMobileSavingErrors: Error {
    case noUUID
    case noLastMeasurementTime
    case savingFailed
    case readingFileError
}

struct SDSessionData: Hashable {
    let uuid: SessionUUID
    var startTime: Date?
    var lastMeasurementTime: Date?
    var needsToBeCreated: Bool
    var averaging: AveragingWindow?
}

struct SDSyncMeasurement: AverageableMeasurement {
    var measuredAt: Date
    var value: Double
    var location: CLLocationCoordinate2D?
}

class SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    @Injected private var fileLineReader: FileLineReader
    @Injected private var averagingService: MeasurementsAveragingService
    @Injected private var persistenceController: PersistenceController
    private var databaseStorage = SDSyncMobileSessionsDatabaseStorage()
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private var sessionUUID: SessionUUID?
    private var location: CLLocationCoordinate2D? = nil
    private var deviceLocation: CLLocationCoordinate2D? = nil
    
    func saveDataToDb(filesDirectoryURL: URL, deviceID: String, deviceLocation: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filesDirectoryURL.path, isDirectory: &isDirectory) else { completion(.success(())); return }
        
        if self.deviceLocation == nil {
            self.deviceLocation = deviceLocation
        }
        
        guard isDirectory.boolValue else {
            process(fileURL: filesDirectoryURL, deviceID: deviceID, completion: completion)
            return
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: filesDirectoryURL.path).compactMap({ filesDirectoryURL.path + "/" + $0 }).compactMap(URL.init(string:))
            var error: Error?
            let group = DispatchGroup()
            
            files.forEach { _ in group.enter() }
            
            for file in files {
                // Plik
                process(fileURL: file, deviceID: deviceID) { result in
                    switch result {
                    case .success():
                        Log.info("Successfully saved session: \(file.path.split(separator: "/").last ?? "na")")
                        group.leave()
                    case .failure(let failureError):
                        Log.info("Failure for session: \(file.path.split(separator: "/").last ?? "na")")
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
    
    private func process(fileURL: URL, deviceID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionUUIDString = fileURL.path.split(separator: "/").last else {
            completion(.failure(SDMobileSavingErrors.noUUID))
            return
        }
        sessionUUID = SessionUUID(stringLiteral: String(sessionUUIDString))
        
        guard let sessionUUID else { return }
        
        Log.info("Processing mobile session: \(self.sessionUUID)")
        
        guard let processedSession = getSessionData(sessionUUID: sessionUUID, deviceID: deviceID) else {

            Log.info("Ignoring session \(sessionUUID). Moving forward.")
            // should it be success?
            completion(.success(()))
            return
        }
        processFile(sessionUUID: sessionUUID, fileURL: fileURL, session: processedSession, deviceID: deviceID, completion: completion)
    }
    
    private func processFile(sessionUUID: SessionUUID, fileURL: URL, session: SDSessionData, deviceID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var streamsWithMeasurements: [SDStream: [SDSyncMeasurement]] = [:]
        let bufferThreshold = 5000
        var savingFailed = false
        var sessionData = session
        
        // Helper variables for debugging
        var savedLines = 0
        
        guard let lastLineInFile = try? fileLineReader.readLastNonEmptyLine(of: fileURL) else {
            Log.error("Failed to get last line from file for session \(session.uuid)")
            completion(.failure(SDMobileSavingErrors.noLastMeasurementTime))
            return
        }
        
        let parser = Resolver.resolve(SDMeasurementsParser.self, args: deviceID)
        // resolver powinien zwrócić Mini parser
        guard let lastMeasurementTime = parser.getMeasurementTime(lineString: lastLineInFile) else {
            Log.error("Failed to read last measurement time from file")
            completion(.failure(SDMobileSavingErrors.noLastMeasurementTime))
            return
        }
        
        do {
            try parser.enumerateMeasurements(url: fileURL, action: { measurements in
                guard !savingFailed else {
                    return
                }
                
                context.perform {
                    // This happens only with the first line
                    if sessionData.averaging == nil {
                        sessionData.averaging = self.averagingService.calculateAveragingWindow(startTime: sessionData.startTime ?? measurements.date, lastMeasurement: lastMeasurementTime)
                    }
                    
                    guard sessionData.lastMeasurementTime == nil || measurements.date > sessionData.lastMeasurementTime! else {
                        return
                    }
                    
                    self.enqueueForSaving(sessionUUID: sessionUUID, measurements: measurements, buffer: &streamsWithMeasurements, deviceID: deviceID)
                    
                    savedLines += 1
                    guard savedLines == bufferThreshold else { return }
                    
                    do {
                        Log.info("Threshold exceeded, saving data")
                        try self.saveData(streamsWithMeasurements, session: &sessionData)
                        streamsWithMeasurements = [:]
                        savedLines = 0
                    } catch {
                        Log.error("Saving measurements failed")
                        savingFailed = true
                        return
                    }
                }
            })
            
            context.perform {
                guard !savingFailed else {
                    completion(.failure(SDMobileSavingErrors.savingFailed))
                    return
                }
                
                do {
                    try self.saveData(streamsWithMeasurements, session: &sessionData)
                    try self.averageUnaveragedMeasurements(sessionUUID: sessionData.uuid, averagingWindow: sessionData.averaging ?? .zeroWindow)
                    try self.databaseStorage.setStatusToFinishedAndUpdateEndTime(for: sessionData.uuid, context: self.context)
                    try self.context.save()
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(SDMobileSavingErrors.readingFileError))
        }
    }
    
    private func getSessionData(sessionUUID: SessionUUID, deviceID: String) -> SDSessionData? {
        var session: SDSessionData? = nil
        context.performAndWait {
            if let existingSession = try? context.existingSession(uuid: sessionUUID) {
                guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                    Log.info("[SD SYNC] Ignoring session \(existingSession.name ?? "none"), \(sessionUUID)")
                    return
                }
                
                session = SDSessionData(uuid: sessionUUID, startTime: existingSession.startTime, lastMeasurementTime: existingSession.lastMeasurementTime, needsToBeCreated: false)
            } else {
                session = SDSessionData(uuid: sessionUUID, needsToBeCreated: true)
            }
        }
        return session
    }
    
    private func enqueueForSaving(sessionUUID: SessionUUID, measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [SDSyncMeasurement]], deviceID: String) {
        location = location ?? setProperLocation(sessionUUID: sessionUUID, deviceID: deviceID, measurements: measurements)
        
        if deviceID.starts(with: "AirBeamMini") {
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .mini_pm1, header: .pm1), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: measurements.pm1, location: location))
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .mini_pm2_5, header: .pm2_5), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: measurements.pm2_5, location: location))
        } else {
            
            if let f = measurements.f {
                streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .f, header: .f), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: f, location: location))
            }
            if let rh = measurements.rh {
                streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .rh, header: .rh), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: rh, location: location))
            }
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .pm1, header: .pm1), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: measurements.pm1, location: location))
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .pm2_5, header: .pm2_5), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: measurements.pm2_5, location: location))
            if let pm10 = measurements.pm10 {
                streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .pm10, header: .pm10), default: []].append(SDSyncMeasurement(measuredAt: measurements.date, value: pm10, location: location))
            }
        }
    }
    
    private func setProperLocation(sessionUUID: SessionUUID, deviceID: String, measurements: SDCardMeasurementsRow) -> CLLocationCoordinate2D? {
        if deviceID.isMini {
            location = getLastRecordedLocation(sessionUUID: sessionUUID)
            return location
        } else {
            if let lat = measurements.lat, let long = measurements.long {
                return CLLocationCoordinate2D(latitude: lat, longitude: long)
            }
            Log.error("[SD Sync] Something went wrong when adding location to measurements")
            return nil
        }
    }
    
    private func getLastRecordedLocation(sessionUUID: SessionUUID) -> CLLocationCoordinate2D? {
        do {
            let session = try context.existingSession(uuid: sessionUUID)
            let filteredStreams = session.allStreams.filter { $0.allMeasurements?.isEmpty == false }
            let latestMeasurements = filteredStreams.compactMap({ $0.allMeasurements?.last })
            let allLastMeasurements = filteredStreams.compactMap { $0.allMeasurements?.last }
            if let newestMeasurement = allLastMeasurements.max(by: { $0.time < $1.time }),
               let location = newestMeasurement.location {
                return location
            } else {
                return deviceLocation
            }
        } catch {
            Log.error("[SD Sync] Error fetching session from local database")
            return nil
        }
    }
    
    private func saveData(_ streamsWithMeasurements: [SDStream: [SDSyncMeasurement]], session: inout SDSessionData) throws {
        Log.info("[SD Sync] Saving data: \(streamsWithMeasurements.count)")
        // Jeśli coś jeszcze jest nie tak to może być kwestia
        //AirCasting.SDCardCSVFileFactory.Header.pm2_5 może potrzebujemy headerów też mini? - sprawdzic na androidzie
        if session.needsToBeCreated {
            try saveNewSessionWithStreams(streamsWithMeasurements: streamsWithMeasurements, sessionData: &session)
        } else {
            Log.info("[SD Sync] saving measurements for existing session")
            try saveMeasurementsForExistingSession(streamsWithMeasurements: streamsWithMeasurements, sessionData: session)
        }
        
        do {
            Log.info("[SD Sync] Saving context")
            try self.context.save()
        } catch {
            Log.error("[SD Sync] context save failed")
            throw error
        }
    }
    
    private func saveNewSessionWithStreams(streamsWithMeasurements: [SDStream: [SDSyncMeasurement]], sessionData: inout SDSessionData) throws {
        guard let location = streamsWithMeasurements.values.first?.first?.location, let time = streamsWithMeasurements.values.first?.first?.measuredAt else {
            Log.error("[SD Sync] No location and time")
            return
        }
        let sessionEntity = databaseStorage.createSession(uuid: sessionData.uuid, location: location, time: time, context: context)
        try saveStreams(streamsWithMeasurements: streamsWithMeasurements, session: sessionEntity, averagingWindow: sessionData.averaging ?? .zeroWindow)
        sessionData.needsToBeCreated = false
    }
    
    private func saveMeasurementsForExistingSession(streamsWithMeasurements: [SDStream: [SDSyncMeasurement]], sessionData: SDSessionData) throws {
        let session = try context.existingSession(uuid: sessionData.uuid)
        try saveStreams(streamsWithMeasurements: streamsWithMeasurements, session: session, averagingWindow: sessionData.averaging ?? .zeroWindow)
    }
    
    private func saveStreams(streamsWithMeasurements: [SDStream: [SDSyncMeasurement]], session: SessionEntity, averagingWindow: AveragingWindow) throws {
        try streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [SDSyncMeasurement]) in
            try saveStream(sdStream: sdStream, measurements: measurements, session: session, averagingWindow: averagingWindow)
        }
    }
    
    private func saveStream(sdStream: SDStream, measurements: [SDSyncMeasurement], session: SessionEntity, averagingWindow: AveragingWindow) throws {
        var existingStream = session.streamWith(sensorName: sdStream.name.rawValue)
        if existingStream == nil {
            existingStream = try databaseStorage.createMeasurementStream(for: session, sensorName: sdStream.name, deviceID: sdStream.deviceID, context: context)
        }
        addMeasurements(measurements, toStream: existingStream!, averaging: averagingWindow)
    }
    
    private func addMeasurements(_ measurements: [SDSyncMeasurement], toStream stream: MeasurementStreamEntity, averaging: AveragingWindow) {
        Log.info("[SD SYNC] SAVING MEASUREMENTS WITH AVERAGING")
        guard averaging != .zeroWindow else {
            measurements.forEach( { databaseStorage.addMeasurement(to: stream, measurement: $0, averagingWindow: .zeroWindow, context: context) })
            return
        }
        
        guard let sessionStartTime = stream.session?.startTime, let firstMeasurementTime = measurements.first?.measuredAt else {
            Log.error("No session start time or last measurement time")
            return
        }
        
        let secondsFromTheStartOfLastAveragingWindow = Int(firstMeasurementTime.timeIntervalSince(sessionStartTime)) % averaging.rawValue
        
        let intervalStart = firstMeasurementTime.addingTimeInterval(TimeInterval(averaging.rawValue - secondsFromTheStartOfLastAveragingWindow))
        
        let measurementsReminder = averagingService.averageMeasurementsWithReminder(measurements: measurements, startTime: intervalStart, averagingWindow: averaging) { measurement, _ in
            databaseStorage.addMeasurement(to: stream, measurement: measurement, averagingWindow: averaging, context: context)
        }
        
        measurementsReminder.forEach({ databaseStorage.addMeasurement(to: stream, measurement: $0, averagingWindow: .zeroWindow, context: context) })
    }
    
    private func averageUnaveragedMeasurements(sessionUUID: SessionUUID, averagingWindow: AveragingWindow) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        try sessionEntity.allStreams.forEach({
            try averageUnaveragedMeasurements(stream: $0, averagingWindow: averagingWindow)
            try databaseStorage.sortAllMeasurements(stream: $0, context: context)
        })
    }
    
    private func averageUnaveragedMeasurements(stream: MeasurementStreamEntity, averagingWindow: AveragingWindow) throws {
        Log.info("[SD SYNC] Averaging unaveraged measurements for stream \(stream.sensorName ?? "with no name")")
        guard averagingWindow != .zeroWindow else {
            return
        }
        
        let measurements = try databaseStorage.fetchUnaveragedMeasurements(currentWindow: averagingWindow, stream: stream, context: context)
        
        guard let intervalStart = stream.session?.startTime else { Log.error("No session start time!"); return }
        
        let reminderMeasurements = averagingService.averageMeasurementsWithReminder(
            measurements: measurements,
            startTime: intervalStart,
            averagingWindow: averagingWindow) { averagedMeasurement, sourceMeasurements in
                databaseStorage.addMeasurement(to: stream, measurement: averagedMeasurement, averagingWindow: averagingWindow, context: context)
                sourceMeasurements.forEach(context.delete(_:))
                try? context.save()
            }
        
        reminderMeasurements.forEach(context.delete(_:))
        try context.save()
    }
}
