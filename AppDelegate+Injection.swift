// Created by Lunar on 10/01/2022.
//

import Foundation

import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        main.register { PersistenceController(inMemory: false) }.scope(.application)
        main.register { resolve() as PersistenceController as SessionsFetchable }
        main.register { resolve() as PersistenceController as SessionRemovable }
        main.register { resolve() as PersistenceController as SessionInsertable }
        
        main.register { CoreDataMeasurementStreamStorage() as MeasurementStreamStorage }.scope(.cached)
        
        main.register { MicrophoneManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { AveragingService(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
    }
}
