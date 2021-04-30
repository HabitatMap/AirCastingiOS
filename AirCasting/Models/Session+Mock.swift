//
//  Session+Mock.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation

extension Session {
    
    static var mock: Session {
        let context = PersistenceController.shared.container.viewContext
        let session: Session = try! context.newOrExisting(uuid: SessionUUID(rawValue: "mock")!)
        session.type = .mobile
        // ...
        return session
    }
    
}



