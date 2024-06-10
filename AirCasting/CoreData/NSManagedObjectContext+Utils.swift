//
//  NSManagedObjectContext+Utils.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    struct MissingSessionEntityError: Swift.Error {
        let uuid: SessionUUID
    }
    
    enum MeasurementsDeletion: Error {
        case errorWhenFetchingRequest(_: String)
    }
    
    func deleteMeasurements(thresholdInSeconds: Double, stream: MeasurementStreamEntity) throws {
        let req: NSFetchRequest<MeasurementEntity> = NSFetchRequest(entityName: "MeasurementEntity")
        req.predicate = NSPredicate(format: "time < %@ AND measurementStream == %@",
                                    NSDate(timeIntervalSince1970: thresholdInSeconds), stream)
        do {
            let measurements = try self.fetch(req)
            measurements.forEach { Log.info("Removing measurement for stream: \($0.measurementStream.sensorName ?? "no name") from \(String(describing: $0.time))"); self.delete($0) }
        } catch {
            throw error
        }
    }
    
    func existingSession(uuid: SessionUUID) throws -> SessionEntity  {
        let fetchRequest: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid.rawValue)

        let results = try self.fetch(fetchRequest)
        if let existing  = results.first {
            return existing
        }
        // TODO: Make this func returning an optional
        throw MissingSessionEntityError(uuid: uuid)
    }
    
    func optionalExistingSession(uuid: SessionUUID) throws -> SessionEntity? {
        do {
            return try existingSession(uuid: uuid)
        } catch is MissingSessionEntityError {
            return nil
        } catch {
            throw error
        }
    }
    
    enum ExternalSessionEntityError: Error {
        case noSession(with: String)
        case moreThanOneSession(with: String)
    }
    
    func existingExternalSession(uuid: SessionUUID) throws -> ExternalSessionEntity {
        let fetchRequest: NSFetchRequest<ExternalSessionEntity> = ExternalSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid.rawValue)

        let results = try self.fetch(fetchRequest)
        
        guard let existing = results.first else {
            throw ExternalSessionEntityError.noSession(with: uuid.rawValue)
        }
        
        guard results.count == 1 else {
            throw ExternalSessionEntityError.moreThanOneSession(with: uuid.rawValue)
        }
        
        return existing
    }
    
    func optionalExistingExternalSession(uuid: SessionUUID) throws -> ExternalSessionEntity? {
        do {
            return try existingExternalSession(uuid: uuid)
        } catch ExternalSessionEntityError.noSession {
            return nil
        } catch {
            throw error
        }
    }
    
    func existingSessionable(uuid: SessionUUID) throws -> Sessionable? {
        if let session = try optionalExistingSession(uuid: uuid) { return session }
        if let externalSession = try optionalExistingExternalSession(uuid: uuid) { return externalSession }
        return nil
    }

    // Checks if session/measurementStream exists, if not, creates a new one
    func newOrExisting<T: NSManagedObject & Identifiable>(id: T.ID) throws -> T  {
        let className = NSStringFromClass(T.classForCoder())
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        fetchRequest.predicate = NSPredicate(format: "id == \(id)")
        
        let results = try self.fetch(fetchRequest)
        if let existing  = results.first {
            return existing
        }
        
        let new: T = T(context: self)
        new.setValue(id, forKey: "id")
        return new
    }
    
    func newOrExisting<T: NSManagedObject>(uuid: SessionUUID) throws -> T  {
        let className = NSStringFromClass(T.classForCoder())
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid.rawValue)
        
        let results = try self.fetch(fetchRequest)
        if let existing  = results.first {
            return existing
        }
        
        let new: T = T(context: self)
        new.setValue(uuid.rawValue, forKey: "uuid")
        return new
    }
}

extension NSManagedObjectContext {

    func existingObject<T: SensorThreshold>(sensorName: String) throws -> T?  {
        let className = NSStringFromClass(T.classForCoder())
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        guard let sensorType = sensorName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last else {
            fetchRequest.predicate = NSPredicate(format: "sensorName == %@", sensorName)
            let results = try self.fetch(fetchRequest)
            return results.first
        }
        fetchRequest.predicate = NSPredicate(format: "sensorName CONTAINS[cd] %@", String(sensorType))
        let results = try self.fetch(fetchRequest)
        return results.first
    }
    
    func createObject<T: SensorThreshold>(sensorName: String) throws -> T  {
        let new: T = T(context: self)
        new.setValue(sensorName, forKey: "sensorName")
        return new
    }

    func newOrExisting<T: SensorThreshold>(sensorName: String) throws -> T  {
        try existingObject(sensorName: sensorName) ?? createObject(sensorName: sensorName)
    }
    
}

extension NSManagedObjectContext {

    func getHighestRowOrder() throws -> Int64? {
        let request: NSFetchRequest<UIStateEntity> = UIStateEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "rowOrder", ascending: false)]
        request.fetchLimit = 1
        return try self.fetch(request).first?.rowOrder
    }
}
