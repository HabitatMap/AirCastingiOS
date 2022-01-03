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

    // Checks if session/stream/measurement exists, if not, creates a new one
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
        #warning("We do not check streams ids, sensor name are not enough to differentiate streams")
        let className = NSStringFromClass(T.classForCoder())
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        fetchRequest.predicate = NSPredicate(format: "sensorName == %@", sensorName)
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
