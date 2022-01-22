//
//  Folder+CoreDataProperties.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/22.
//
//

import Foundation
import CoreData


extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var orderingNumber: Int64
    @NSManaged public var name: String?
    @NSManaged public var breadsCount: Int64
    @NSManaged public var breads: NSSet?

}

// MARK: Generated accessors for breads
extension Folder {

    @objc(addBreadsObject:)
    @NSManaged public func addToBreads(_ value: Bread)

    @objc(removeBreadsObject:)
    @NSManaged public func removeFromBreads(_ value: Bread)

    @objc(addBreads:)
    @NSManaged public func addToBreads(_ values: NSSet)

    @objc(removeBreads:)
    @NSManaged public func removeFromBreads(_ values: NSSet)

}

extension Folder : Identifiable {

}
