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
    func updateAllSessionsMeasurements(completion: @escaping () -> Void)
}

final class DownloadMeasurementsService: MeasurementUpdatingService {
    @Injected private var persistenceController: PersistenceController
    private var refreshTimeInSeconds: Double = 60
    private let fixedSessionService = FixedSessionAPIService()
    private var timerSink: Cancellable?
    private var quickTimerSink: Cancellable?
    private var firstMeasurementTimerSink: Cancellable?
    private var lastFetchCancellableTask: Cancellable?
    @Injected private var removeOldServiceDefault: RemoveOldMeasurements
    
    func start() {
        timerSink = Timer.publish(every: refreshTimeInSeconds, on: .current, in: .common).autoconnect().sink { [weak self] tick in
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
    
    func triggerQuickRefresh() {
        // Fire one fetch immediately so we don't wait a full interval for the
        // first poll. The session row was just created right before this call
        // (`ConfirmCreatingSessionView.createSession`), so as soon as the
        // airbeam pushes its first sample to BE the dashboard card can pick it
        // up on the very next short tick instead of after the 10s gap that the
        // bare `Timer.publish` introduced. Mirrors Android hooking the BE
        // measurements update to the end of fixed-session configuration.
        if !persistenceController.uiSuspended {
            Log.info("Quick refresh started — firing immediate fixed sessions measurements download")
            updateAllSessionsMeasurements()
        }
        quickTimerSink = Timer.publish(every: 2, on: .current, in: .common).autoconnect().sink { [weak self] tick in
            guard !(self?.persistenceController.uiSuspended ?? true) else { return }
            Log.info("Quick timer triggered for fixed sessions measurements download")
            self?.updateAllSessionsMeasurements()
        }
    }
    
    func cancelQuickRefresh() {
        quickTimerSink?.cancel()
    }

    /// Gate the end of fixed-session creation on the airbeam's first BE upload.
    /// Called right after `NewSessionConfig` completes — the device then joins
    /// wifi/cellular and pushes its first sample to BE, which takes a couple of
    /// seconds and is invisible to the phone (BLE is already torn down). We poll
    /// that one session until the first measurement is persisted (or `timeout`
    /// elapses), then call `completion` on the main queue so the caller can
    /// navigate to the dashboard with the card already populated instead of
    /// landing on the "Measurements will appear in 3 minutes" placeholder.
    /// Mirrors Android hooking the BE measurements update to the airbeam's
    /// first measurement at the end of fixed-session configuration.
    func awaitFirstMeasurement(for sessionUUID: SessionUUID,
                               pollInterval: TimeInterval = 2,
                               timeout: TimeInterval = 30,
                               completion: @escaping () -> Void) {
        firstMeasurementTimerSink?.cancel()
        let maxAttempts = max(1, Int((timeout / pollInterval).rounded(.up)))
        var attempts = 0
        var inFlight = false
        var finished = false
        let finish: () -> Void = { [weak self] in
            guard !finished else { return }
            finished = true
            self?.firstMeasurementTimerSink?.cancel()
            self?.firstMeasurementTimerSink = nil
            DispatchQueue.main.async { completion() }
        }
        let poll: () -> Void = { [weak self] in
            guard let self = self, !finished, !inFlight else { return }
            inFlight = true
            attempts += 1
            let attempt = attempts
            self.fetchFirstMeasurementCount(for: sessionUUID) { hasMeasurements in
                inFlight = false
                if hasMeasurements {
                    Log.info("First measurement landed for \(sessionUUID) after \(attempt) attempt(s) — finishing session creation")
                    finish()
                } else if attempt >= maxAttempts {
                    Log.info("First-measurement wait timed out for \(sessionUUID) after \(attempt) attempts — finishing session creation anyway")
                    finish()
                }
            }
        }
        // Fire immediately, then keep polling on the interval until data lands.
        poll()
        firstMeasurementTimerSink = Timer.publish(every: pollInterval, on: .current, in: .common).autoconnect().sink { [weak self] _ in
            guard !(self?.persistenceController.uiSuspended ?? true) else { return }
            poll()
        }
    }

    /// Fetches the given fixed session once, persists whatever measurements come
    /// back, and reports whether the BE returned any. Used by
    /// `awaitFirstMeasurement` to detect the airbeam's first upload.
    private func fetchFirstMeasurementCount(for sessionUUID: SessionUUID, completion: @escaping (Bool) -> Void) {
        firstMeasurementSyncDate(for: sessionUUID) { [weak self] syncDate in
            guard let self = self else { return }
            self.lastFetchCancellableTask = self.fixedSessionService.getFixedMeasurement(uuid: sessionUUID, lastSync: syncDate) { [weak self] result in
                switch result {
                case .success(let output):
                    let hasMeasurements = (output.streams.first?.value.measurements.count ?? 0) > 0
                    self?.processServiceOutput(output, for: sessionUUID, isExternal: false) {
                        completion(hasMeasurements)
                    }
                case .failure(let error):
                    Log.error("awaitFirstMeasurement fetch failed for \(sessionUUID): \(error)")
                    completion(false)
                }
            }
        }
    }

    private func firstMeasurementSyncDate(for sessionUUID: SessionUUID, completion: @escaping (Date) -> Void) {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", sessionUUID.rawValue)
        let context = persistenceController.editContext
        context.perform { [unowned self] in
            let session = try? context.fetch(request).first
            completion(self.getSyncDate(for: session))
        }
    }
    
    private func updateMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, isExternal: Bool, completion: @escaping () -> Void) {
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: sessionUUID, lastSync: lastSynced) { [weak self] in
            self?.processServiceResponse($0, for: sessionUUID, isExternal: isExternal, completion: completion)
        }
    }
    
    func updateAllSessionsMeasurements(completion: @escaping () -> Void = {}) {
        getAllSessionsData() { [unowned self] sessionsData in
            Log.info("Scheduled measurements update triggered (session count: \(sessionsData.count))")
            let group = DispatchGroup()
            sessionsData.forEach { _ in group.enter() }
            sessionsData.forEach {
                self.updateMeasurements(for: $0.uuid, lastSynced: $0.lastSynced, isExternal: $0.isExternal) { group.leave() }
            }
            
            group.notify(queue: DispatchQueue.global()) {
                Log.info("Measurements downloading completed")
                completion()
            }
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
        // BE compares `last_measurement_sync` against the raw numerals it
        // stored for `Measurement#time` via `Utils.to_local_as_utc(epoch,
        // session.time_zone)`. V2 indoor / locationless sessions store those
        // numerals as real UTC (BE `time_zone == UTC`), while iOS shifted
        // them to the fakeUTC convention on persist
        // (`UpdateSessionParamsService.shiftEndAndMeasurements`). Sending
        // the fakeUTC Date directly through `ISO8601(UTC)` formats it as the
        // phone-wall-clock numerals — for a UTC+2 phone that's 2h ahead of
        // BE's stored numerals, so BE returns an empty page and only the
        // first batch ever lands. Undo the shift here so the cursor lines
        // up with BE's stored numerals; outdoor V2 + V1 stay untouched
        // because their numerals already match `ISO8601(UTC)` directly.
        guard let session = session,
              UpdateSessionParamsService.sessionRequiresUtcShift(session: session) else {
            return syncDate
        }
        return syncDate.convertedFromUTCToLocal
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
                                        for sessionUUID: SessionUUID, isExternal: Bool, completion: @escaping () -> Void = {}) {
        switch response {
        case .success(let response):
            processServiceOutput(response, for: sessionUUID, isExternal: isExternal, completion: completion)
        case .failure(let error):
            Log.error("Failed to fetch measurements for uuid '\(sessionUUID). Session external: \(isExternal)' \(error)")
            completion()
        }
    }

    private func processServiceOutput(_ output: FixedSession.FixedMeasurementOutput,
                                      for sessionUUID: SessionUUID,
                                      isExternal: Bool,
                                      completion: @escaping () -> Void = {}) {
        Log.info("Processing download measurements response for: \(sessionUUID)")
        let context = persistenceController.editContext
        context.perform {
            context.refreshAllObjects()
            do {
                defer { completion() }
                if !isExternal {
                    Log.info("Processing regular session response")
                    let session: SessionEntity = try context.newOrExisting(uuid: output.uuid)
                    
                    if output.streams.first?.value.measurements.count ?? 0 > 0 {
                        self.cancelQuickRefresh()
                    }
                    try UpdateSessionParamsService().updateSessionsParams(session: session, output: output)
                    try self.removeOldServiceDefault.removeOldestMeasurements(in: context,
                                                                              from: sessionUUID)
                } else {
                    Log.info("Processing external session response")
                    let session = try context.existingExternalSession(uuid: sessionUUID)
                    let isIndoor = output.is_indoor ?? false
                    session.endTime = output.end_time.shiftedForFixedSession(isIndoor: isIndoor)
                    output.streams.forEach({ stream in
                        if let sessionStream = session.allStreams.first(where: { $0.sensorName == stream.key }) {
                            stream.value.measurements.forEach({ measurement in
                                let newMeasurement = MeasurementEntity(context: context)
                                newMeasurement.location = CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)
                                newMeasurement.time = measurement.time.shiftedForFixedSession(isIndoor: isIndoor)
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
