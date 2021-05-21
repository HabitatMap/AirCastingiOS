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
        // ...
        return session
    }
}

#endif
