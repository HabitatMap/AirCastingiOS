// Created by Lunar on 10/01/2022.
//

import Foundation

import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        main.register { PersistenceController(inMemory: false) }
        main.register { resolve() as PersistenceController as SessionsFetchable }
        main.register { resolve() as PersistenceController as SessionRemovable }
        main.register { resolve() as PersistenceController as SessionInsertable }
        
        main.register { CoreDataMeasurementStreamStorage() as MeasurementStreamStorage }
        
        main.register { MicrophoneManager(measurementStreamStorage: Resolver.resolve()) }
    }
}
