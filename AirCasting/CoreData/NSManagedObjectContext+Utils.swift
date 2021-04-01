//
//  NSManagedObjectContext+Utils.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    // Checks if session/stream/measurement exists, if not, creates a new one
    func newOrExisting<T: NSManagedObject>(id: Int) -> T  {
        let className = NSStringFromClass(T.classForCoder())
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        fetchRequest.predicate = NSPredicate(format: "id == %li", id)
        
        let results = try! self.fetch(fetchRequest)
        if let existing  = results.first {
            return existing
        }
        
        let new: T = T(context: self)
        new.setValue(id, forKey: "id")
        return new
    }
    
    func newOrExisting<T: NSManagedObject>(uuid: String) -> T  {
        let className = NSStringFromClass(T.classForCoder())
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
        
        let results = try! self.fetch(fetchRequest)
        if let existing  = results.first {
            return existing
        }
        
        let new: T = T(context: self)
        new.setValue(uuid, forKey: "uuid")
        return new
    }
}
