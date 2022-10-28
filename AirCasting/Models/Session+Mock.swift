//
//  Session+Mock.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation
import Resolver

#if DEBUG
extension SessionEntity {
    
    static var mock: SessionEntity {
        let context = Resolver.resolve(PersistenceController.self).viewContext
        let session: SessionEntity = try! context.newOrExisting(uuid: SessionUUID(rawValue: "mock")!)
        session.type = .mobile
        session.name = "Session mock"
        // ...
                
        return session
    }
    
    static func mock(uuid: String) -> SessionEntity {
        let context = Resolver.resolve(PersistenceController.self).viewContext
        let session: SessionEntity = try! context.newOrExisting(uuid: SessionUUID(rawValue: uuid)!)
        session.type = .mobile
        session.name = "Session mock"
        // ...
                
        return session
    }
}

extension MeasurementStreamEntity {
    
    static var mock: MeasurementStreamEntity {
        let context = Resolver.resolve(PersistenceController.self).viewContext
        let stream: MeasurementStreamEntity = try! context.newOrExisting(id: 1_001)
        
        for i in 0...10 {
            let measuremennt: MeasurementEntity = MeasurementEntity(context: context)
            measuremennt.value = Double(arc4random() % 150)
            measuremennt.time = DateBuilder.getRawDate().addingTimeInterval(-3600).addingTimeInterval(10 * Double(i))
        }
        
        return stream
    }
    
}
#endif
