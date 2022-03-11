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
    
    
//    #warning("This seems odd and is also working odd. I don't think this is correct implementation")
//    // Explaination:
//    // I'm not sure why is that happening, but the fetch inside this function is returning multiple streams
//    // not associated with a single session. It causes the calling code to sometimes modify an incorrect
//    // stream object. I found this when implementing the url saving feature after uploads
//    // (https://github.com/HabitatMap/AirCastingiOS/pull/578) - I used the `Databse`s
//    // `func insertOrUpdateSessions(_ sessions: [Database.Session], completion: ((Error?) -> Void)?)`
//    // to achieve session URL update and it started acting weird - adding streams to existing dB sessions
//    // etc.. I think the root of the problem is that session streams don't have a unique identifiers
//    // and we decided to use a NSManagedObjectID instead. Somehow it's not working right, but when I added
//    // additional session-id constraint it started to behave somewhat properly. But this is a blind patch
//    // and should be investigated and resolved.
//    // Issue: https://github.com/HabitatMap/AirCastingiOS/issues/579
//    
//    // Checks if stream exists, if not, creates a new one
//    func newOrExisting<T: NSManagedObject>(streamID: MeasurementStreamID, for session: SessionUUID? = nil) throws -> T  {
//        let className = NSStringFromClass(T.classForCoder())
//        let fetchRequest = NSFetchRequest<T>(entityName: className)
//        fetchRequest.predicate = NSPredicate(format: "id == \(streamID)")
//        if let session = session {
//            fetchRequest.predicate = NSCompoundPredicate(type: .and,
//                                                         subpredicates: [fetchRequest.predicate!,
//                                                                         NSPredicate(format: "session.uuid == %@", session.rawValue)])
//        }
//        
//        let results = try self.fetch(fetchRequest)
//        if let existing  = results.first { return existing }
//        
//        let new: T = T(context: self)
//        new.setValue(streamID, forKey: "id")
//        return new
//    }
    
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

extension NSManagedObjectContext {

    func getHighestRowOrder() throws -> Int64? {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "rowOrder", ascending: false)]
        request.fetchLimit = 1
        return try self.fetch(request).first?.rowOrder
    }
}
