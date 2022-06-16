// Created by Lunar on 16/06/2022.
//

import Foundation
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

        let results = try context.fetch(fetchRequest)
        return !results.isEmpty
    }
}
