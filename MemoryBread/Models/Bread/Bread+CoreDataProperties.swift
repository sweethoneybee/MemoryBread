//
//  Bread+CoreDataProperties.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//
//

import Foundation
import CoreData


extension Bread {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bread> {
        return NSFetchRequest<Bread>(entityName: "Bread")
    }

    @NSManaged public var createdTime: Date?
    @NSManaged public var touch: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var directoryName: String?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var separatedContent: [String]?
    @NSManaged public var filterIndexes: [[Int]]?

}

extension Bread : Identifiable {

}
