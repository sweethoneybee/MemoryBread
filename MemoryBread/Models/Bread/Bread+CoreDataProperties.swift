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
    @NSManaged public var id: NSNumber?
    @NSManaged public var directoryName: String?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var separatedContent: [String]?
    @NSManaged public var filterIndexes: [[Int]]?

}

extension Bread : Identifiable {
    // TODO: 분리해야함
    func updateFilterIndexes(with items: [BreadViewController.WordItem]) {
        var newFilterIndexes: [[Int]] = Array(repeating: [], count: FilterColor.count)
        items.enumerated().forEach { (itemIndex, item) in
            if let colorIndex = FilterColor.colorIndex(for: item.filterColor) {
                newFilterIndexes[colorIndex].append(itemIndex)
            }
        }
        filterIndexes = newFilterIndexes
        touch = Date.now
    }
    
    func updateContent(_ newContent: String) {
        content = newContent
        separatedContent = newContent.components(separatedBy: ["\n", " "])
        filterIndexes = Array(repeating: [], count: FilterColor.count)
        touch = Date.now
    }
}
