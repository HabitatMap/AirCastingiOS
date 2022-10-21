// Created by Lunar on 20/10/2022.
//

import Foundation
import CoreData

protocol AveragingServiceStorage {
    func accessStorage(_ task: @escaping(HiddenAveragingServiceStorage) -> Void)
}

protocol HiddenAveragingServiceStorage {
    func observerForMobileSessions() -> NSFetchedResultsController<SessionEntity>
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity
    func fetchUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) throws -> [MeasurementEntity]
    func deleteMeasurements(_ measurements: [MeasurementEntity])
    func save() throws
}

final class DefaultAveragingServiceStorage: AveragingServiceStorage {
    private let context: NSManagedObjectContext
    private lazy var hiddenStorage: HiddenAveragingServiceStorage = DefaultHiddenAveragingServiceStorage(context: context)
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// All actions performed on AveragingServiceStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenAveragingServiceStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

final class DefaultHiddenAveragingServiceStorage: HiddenAveragingServiceStorage {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func observerForMobileSessions() -> NSFetchedResultsController<SessionEntity> {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND status == %i",
                                        SessionType.mobile.rawValue,
                                        SessionStatus.RECORDING.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }
    
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }
    
    func fetchUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) throws -> [MeasurementEntity] {
        let fetchRequest = fetchRequestForUnaveragedMeasurements(currentWindow: currentWindow, stream: stream)
        return try context.fetch(fetchRequest)
    }
    
    func deleteMeasurements(_ measurements: [MeasurementEntity]) {
        measurements.forEach(context.delete(_:))
    }
    
    func save() throws {
        try self.context.save()
    }
    
    private func fetchRequestForUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) -> NSFetchRequest<MeasurementEntity> {
        let fetchRequest = MeasurementEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "averagingWindow != %d AND measurementStream == %@", currentWindow.rawValue, stream)
        return fetchRequest
    }
}
