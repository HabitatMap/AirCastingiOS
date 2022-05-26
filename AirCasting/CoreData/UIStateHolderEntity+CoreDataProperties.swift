//
//  UIStateHolderEntity+CoreDataProperties.swift
//  
//
//  Created by Pawel Gil on 26/05/2022.
//
//

import Foundation
import CoreData


extension UIStateHolderEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UIStateHolderEntity> {
        return NSFetchRequest<UIStateHolderEntity>(entityName: "UIStateHolderEntity")
    }

    @NSManaged public var startTime: Date?
    @NSManaged public var followedAt: Date?
    @NSManaged public var userInterface: UIStateEntity?

}
