//
//  NSManagedObjectContext+Utils.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func existingSession(uuid: SessionUUID) throws -> SessionEntity  {
        struct MissingSessionEntityError: Swift.Error {
            let uuid: SessionUUID
        }
        let fetchRequest: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid.rawValue)

        let results = try self.fetch(fetchRequest)
        if let existing  = results.first {
            return existing
        }
        throw MissingSessionEntityError(uuid: uuid)
    }
    
    func existingExternalSession(uuid: String) throws -> ExternalSessionEntity  {
        enum ExternalSessionEntityError: Error {
            case noSession(with: String)
            case moreThanOneSession(with: String)
        }
        let fetchRequest: NSFetchRequest<ExternalSessionEntity> = ExternalSessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)

        let results = try self.fetch(fetchRequest)
        
        guard let existing = results.first else {
            throw ExternalSessionEntityError.noSession(with: uuid)
        }
        
        guard results.count == 1 else {
            throw ExternalSessionEntityError.moreThanOneSession(with: uuid)
        }
        
        return existing
    }

    // Checks if session/measurement exists, if not, creates a new one
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
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "rowOrder", ascending: false)]
        request.fetchLimit = 1
        return try self.fetch(request).first?.rowOrder
    }
}
