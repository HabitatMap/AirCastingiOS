//
//  Session+Mock.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation

#if DEBUG
extension SessionEntity {
    
    static var mock: SessionEntity {
        let context = PersistenceController.shared.viewContext
        let session: SessionEntity = try! context.newOrExisting(uuid: SessionUUID(rawValue: "mock")!)
        session.type = .mobile
        session.name = "Session mock"
        // ...
                
        return session
    }
}

extension MeasurementStreamEntity {
    
    static var mock: MeasurementStreamEntity {
        let context = PersistenceController.shared.viewContext
        let stream: MeasurementStreamEntity = try! context.newOrExisting(id: 1_001)
        
        for i in 0...10 {
            let measuremennt: MeasurementEntity = try! context.newOrExisting(id: Int64(i))
            measuremennt.value = Double(arc4random() % 150)
            measuremennt.time = Date().addingTimeInterval(-3600).addingTimeInterval(10 * Double(i))
        }
        
        return stream
    }
    
}
#endif
