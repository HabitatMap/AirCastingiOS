// Created by Lunar on 16/06/2022.
//

import CoreData

protocol SessionEntityStore {
    func anyLocationlessSessionsPresent() throws -> Bool
}

struct DefaultSessionEntityStore: SessionEntityStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func anyLocationlessSessionsPresent() throws -> Bool  {
        let fetchRequest: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "locationless = %d", true)

        var result: [SessionEntity] = [SessionEntity]()
        var error: Error? = nil
        context.performAndWait {
            do {
                result = try context.fetch(fetchRequest)
            } catch let anError {
                error = anError
            }
        }
        if let error = error { throw error }
        return !result.isEmpty
    }
}
