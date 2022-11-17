//
//  DownloadMeasurmentsService.swift
//  AirCasting
//
//  Created by Lunar on 25/03/2021.
//

import Foundation
import CoreData
import Combine
import Resolver
import CoreLocation

protocol MeasurementUpdatingService {
    func start()
    func downloadMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, completion: @escaping () -> Void)
    func updateAllSessionsMeasurements()
}

final class DownloadMeasurementsService: MeasurementUpdatingService {
    @Injected private var persistenceController: PersistenceController
    private let fixedSessionService = FixedSessionAPIService()
    private var timerSink: Cancellable?
    private var lastFetchCancellableTask: Cancellable?
    @Injected private var removeOldServiceDefault: RemoveOldMeasurements
    
    func start() {
        updateAllSessionsMeasurements()
        timerSink = Timer.publish(every: 60, on: .current, in: .common).autoconnect().sink { [weak self] tick in
            guard !(self?.persistenceController.uiSuspended ?? true) else { return }
            Log.info("Timer triggered for fixed sessions measurements download")
            self?.updateAllSessionsMeasurements()
        }
    }

    func downloadMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, completion: @escaping () -> Void) {
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: sessionUUID, lastSync: lastSynced) { [weak self] in
            self?.processServiceResponse($0, for: sessionUUID, isExternal: false, completion: completion)
        }
    }

    private func updateMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, isExternal: Bool) {
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: sessionUUID, lastSync: lastSynced) { [weak self] in
            self?.processServiceResponse($0, for: sessionUUID, isExternal: isExternal)
        }
    }

    func updateAllSessionsMeasurements() {
        getAllSessionsData() { [unowned self] sessionsData in
            Log.info("Scheduled measurements update triggered (session count: \(sessionsData.count))")
            sessionsData.forEach { self.updateMeasurements(for: $0.uuid, lastSynced: $0.lastSynced, isExternal: $0.isExternal) }
        }
    }

    private func getAllSessionsData(completion: @escaping ([(uuid: SessionUUID, lastSynced: Date, isExternal: Bool)]) -> Void) {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "followedAt != NULL")

        let externalSessionsRequest = ExternalSessionEntity.fetchRequest()
        externalSessionsRequest.predicate = NSPredicate(value: true)

        let context = persistenceController.editContext
        var returnData: [(uuid: SessionUUID, lastSynced: Date, isExternal: Bool)] = []

        context.perform { [unowned self] in
            do {
                let sessions = try context.fetch(request)
                let externalSessions = try context.fetch(externalSessionsRequest)
                let mappedSessions = sessions.map { ($0.uuid, self.getSyncDate(for: $0), $0.isExternal) }
                let mappedExternalSessions = externalSessions.map { ($0.uuid, self.getExternalSessionSyncDate(for: $0), $0.isExternal) }
                returnData = mappedSessions + mappedExternalSessions
                completion(returnData)
            } catch {
                Log.error("Error fetching sessions data: \(error)")
            }
        }
    }

    private func getSyncDate(for session: SessionEntity?) -> Date {
        let lastMeasurementTime = session?.allStreams
            .compactMap(\.lastMeasurementTime)
            .sorted()
            .last
        let syncDate = SyncHelper().calculateLastSync(sessionEndTime: session?.endTime, lastMeasurementTime: lastMeasurementTime)
        return syncDate
    }

    private func getExternalSessionSyncDate(for session: ExternalSessionEntity?) -> Date {
        let lastMeasurementTime = session?.allStreams
            .compactMap(\.lastMeasurementTime)
            .sorted()
            .last
        let syncDate = SyncHelper().calculateLastSync(sessionEndTime: session?.endTime, lastMeasurementTime: lastMeasurementTime)
        return syncDate
    }

    private func processServiceResponse(_ response: Result<FixedSession.FixedMeasurementOutput, Error>,
                                        for sessionUUID: SessionUUID, isExternal: Bool, completion: () -> Void = {}) {
        switch response {
        case .success(let response):
            processServiceOutput(response, for: sessionUUID, isExternal: isExternal)
            completion()
        case .failure(let error):
            Log.warning("Failed to fetch measurements for uuid '\(sessionUUID). Session external: \(isExternal)' \(error)")
        }
    }

    private func processServiceOutput(_ output: FixedSession.FixedMeasurementOutput,
                                      for sessionUUID: SessionUUID,
                                      isExternal: Bool) {
        Log.info("Processing download measurements response for: \(sessionUUID)")
        let context = persistenceController.editContext
        context.perform {
            do {
                if !isExternal {
                    Log.info("Processing regular session response")
                    let session: SessionEntity = try context.newOrExisting(uuid: output.uuid)
                    try UpdateSessionParamsService().updateSessionsParams(session: session, output: output)
                    try self.removeOldServiceDefault.removeOldestMeasurements(in: context,
                                                                       from: sessionUUID)
                } else {
                    Log.info("Processing external session response")
                    let session = try context.existingExternalSession(uuid: sessionUUID)
                    session.endTime = output.end_time
                    output.streams.forEach({ stream in
                        if let sessionStream = session.allStreams.first(where: { $0.sensorName == stream.key }) {
                            stream.value.measurements.forEach({ measurement in
                                let newMeasurement = MeasurementEntity(context: context)
                                newMeasurement.location = CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)
                                newMeasurement.time = measurement.time
                                newMeasurement.value = Double(measurement.value)
                                sessionStream.addToMeasurements(newMeasurement)
                            })
                        }
                    })
                    try self.removeOldServiceDefault.removeOldestMeasurements(in: context,
                                                                              from: sessionUUID)
                }
                try context.save()
            } catch let error as UpdateSessionParamsService.Error {
                Log.error("Failed to update session params: \(error)")
            } catch let error as DefaultRemoveOldMeasurementsService.Error {
                Log.error("Failed to remove old measaurements from fixed session \(error)")
            } catch {
                Log.error("Save error: \(error)")
            }
        }
    }
}

class SyncHelper {

    func calculateLastSync(sessionEndTime: Date?, lastMeasurementTime: Date?) -> Date {
        let measurementTimeframe: Double = 24 * 60 * 60 // 24 hours in seconds

        guard let sessionEndTime = sessionEndTime else { return DateBuilder.getFakeUTCDate() }
        let sessionEndTimeSeconds = sessionEndTime.timeIntervalSince1970
        let last24hours = DateBuilder.getDateWithTimeIntervalSince1970((sessionEndTimeSeconds - measurementTimeframe))

        guard let lastMeasurementTime = lastMeasurementTime else { return last24hours }
        let lastMeasurementSeconds = lastMeasurementTime.timeIntervalSince1970

        return ((sessionEndTimeSeconds - lastMeasurementSeconds) < measurementTimeframe) ? lastMeasurementTime : last24hours
    }
}
