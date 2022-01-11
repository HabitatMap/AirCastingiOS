// Created by Lunar on 10/01/2022.
//

import Foundation

import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        main.register { PersistenceController(inMemory: false) }
            .implements(SessionsFetchable.self)
            .implements(SessionRemovable.self)
            .implements(SessionInsertable.self)
            .scope(.application)
        
        main.register { CoreDataMeasurementStreamStorage() as MeasurementStreamStorage }.scope(.cached)
        main.register { MicrophoneManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { AveragingService(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { MobilePeripheralSessionManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { BluetoothManager(mobilePeripheralSessionManager: Resolver.resolve()) }
            .implements(BluetoothConnector.self)
            .scope(.cached)
        main.register { DefaultBluetoothHandler() as BluetoothHandler }
            
        
    }
}
