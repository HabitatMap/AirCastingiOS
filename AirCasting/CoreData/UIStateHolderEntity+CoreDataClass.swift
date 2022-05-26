//
//  UIStateHolderEntity+CoreDataClass.swift
//  
//
//  Created by Pawel Gil on 26/05/2022.
//
//

import Foundation
import CoreData

@objc(UIStateHolderEntity)
public class UIStateHolderEntity: NSManagedObject {
    public var status: SessionStatus? {
        get { (value(forKey: "status") as? Int).flatMap(SessionStatus.init(rawValue:)) }
        set { setValue(newValue?.rawValue, forKey: "status") }
    }
    
    public var type: SessionType! {
        get { SessionType(rawValue:(value(forKey: "type") as? String ?? "")) }
        set { setValue(newValue.rawValue, forKey: "type") }
    }
}
