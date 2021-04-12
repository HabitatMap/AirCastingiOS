//
//  Session+Mock.swift
//  AirCasting
//
//  Created by Lunar on 22/03/2021.
//

import Foundation

#if DEBUG
extension Session {
    
    static var mock: Session {
        let session = Session(context: PersistenceController.shared.container.viewContext)
        // ...
        return session
    }
    
}

#endif
