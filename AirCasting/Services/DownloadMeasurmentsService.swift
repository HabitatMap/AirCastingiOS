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

protocol MeasurementUpdatingService {
    func start()
    func downloadMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, completion: @escaping () -> Void)
}

final class DownloadMeasurementsService: MeasurementUpdatingService {
    private let authorisationService: RequestAuthorisationService
    @Injected private var persistenceController: PersistenceController
    private let fixedSessionService: FixedSessionAPIService
    private var timerSink: Cancellable?
    private var lastFetchCancellableTask: Cancellable?
    private lazy var removeOldService: RemoveOldMeasurementsService = RemoveOldMeasurementsService()
    
    init(authorisationService: RequestAuthorisationService, baseUrl: BaseURLProvider) {
        self.authorisationService = authorisationService
        self.fixedSessionService = FixedSessionAPIService(authorisationService: authorisationService, baseUrl: baseUrl)
    }

    #warning("Add locking here so updates won't bump on one another")
    func start() {
        updateAllSessionsMeasurements()
        timerSink = Timer.publish(every: 60, on: .current, in: .common).autoconnect().sink { [weak self] tick in
            self?.updateAllSessionsMeasurements()
        }
    }
    
    func downloadMeasurements(for sessionUUID: SessionUUID, lastSynced: Date, completion: @escaping () -> Void) {
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: sessionUUID, lastSync: lastSynced) { [weak self] in
            self?.processServiceResponse($0, for: sessionUUID, completion: completion)
        }
    }
    
    private func updateMeasurements(for sessionUUID: SessionUUID, lastSynced: Date) {
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: sessionUUID, lastSync: lastSynced) { [weak self] in
            self?.processServiceResponse($0, for: sessionUUID)
        }
    }
    
    private func updateAllSessionsMeasurements() {
        getAllSessionsData() { [unowned self] sessionsData in
            Log.info("Scheduled measurements update triggered (session count: \(sessionsData.count))")
            sessionsData.forEach { self.updateMeasurements(for: $0.uuid, lastSynced: $0.lastSynced) }
        }
    }
    
    private func getAllSessionsData(completion: @escaping ([(uuid: SessionUUID, lastSynced: Date)]) -> Void) {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = request.typePredicate(.fixed)
        let context = persistenceController.editContext
        var returnData: [(uuid: SessionUUID, lastSynced: Date)] = []
        context.perform { [unowned self] in
            do {
                let sessions = try context.fetch(request)
                returnData = sessions.map { ($0.uuid, self.getSyncDate(for: $0)) }
                completion(returnData)
            } catch {
                Log.error("Error fetching sessions data: \(error)")
            }
        }
    }
    
    private func getSyncDate(for session: SessionEntity?) -> Date {
        let lastMeasurementTime = session?.allStreams?
            .compactMap(\.lastMeasurementTime)
            .sorted()
            .last
        let syncDate = SyncHelper().calculateLastSync(sessionEndTime: session?.endTime, lastMeasurementTime: lastMeasurementTime)
        return syncDate
    }
    
    private func processServiceResponse(_ response: Result<FixedSession.FixedMeasurementOutput, Error>,
                                        for sessionUUID: SessionUUID, completion: () -> Void = {}) {
        switch response {
        case .success(let response):
            processServiceOutput(response, for: sessionUUID)
            completion()
        case .failure(let error):
            Log.warning("Failed to fetch measurements for uuid '\(sessionUUID)' \(error)")
        }
    }
    
    private func processServiceOutput(_ output: FixedSession.FixedMeasurementOutput,
                                      for sessionUUID: SessionUUID) {
        let context = persistenceController.editContext
        context.perform {
            do {
                let session: SessionEntity = try context.newOrExisting(uuid: output.uuid)
                try UpdateSessionParamsService().updateSessionsParams(session: session, output: output)
                try self.removeOldService.removeOldestMeasurements(in: context,
                                                              uuid: sessionUUID)
                try context.save()
            } catch let error as UpdateSessionParamsService.Error {
                Log.error("Failed to update session params: \(error)")
            } catch let error as RemoveOldMeasurementsService.Error {
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
        
        guard let sessionEndTime = sessionEndTime else { return Date().currentUTCTimeZoneDate }
        let sessionEndTimeSeconds = sessionEndTime.timeIntervalSince1970
        
        let last24hours = Date(timeIntervalSince1970: (sessionEndTimeSeconds - measurementTimeframe))
        
        guard let lastMeasurementTime = lastMeasurementTime else { return last24hours }
        let lastMeasurementSeconds = lastMeasurementTime.timeIntervalSince1970
        
        return ((sessionEndTimeSeconds - lastMeasurementSeconds) < measurementTimeframe) ? lastMeasurementTime : last24hours
    }
}
