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
    @NSManaged public var selectedFilters: [Int]?
}

extension Bread : Identifiable {
    static func makeBasicBread(context: NSManagedObjectContext) -> Bread {
        return Bread(
            context: context,
            touch: Date(),
            directoryName: "기본",
            title: LocalizingHelper.freshBread,
            content: "",
            separatedContent: [],
            filterIndexes: Array(repeating: [], count: FilterColor.count),
            selectedFilters: nil
        )
    }
    
    /// 최초 튜토리얼 세팅에만 사용해야 함.
    func updateFilterIndexes(usingIndexes indexes: [(Int, Int)]) {
        var newFilterIndexes: [[Int]] = Array(repeating: [], count: FilterColor.count)
        indexes.forEach { (index, colorIndex) in
            newFilterIndexes[colorIndex].append(index)
        }
        filterIndexes = newFilterIndexes
    }
    
    func updateFilterIndexes(with items: [WordItemModel.Item]) {
        var newFilterIndexes: [[Int]] = Array(repeating: [], count: FilterColor.count)
        items.enumerated().forEach { (itemIndex, item) in
            if let colorIndex = FilterColor.colorIndex(for: item.filterColor) {
                newFilterIndexes[colorIndex].append(itemIndex)
            }
        }
        filterIndexes = newFilterIndexes
        touch = Date()
    }
    
    func updateContent(_ newContent: String) {
        content = newContent
        separatedContent = newContent.components(separatedBy: ["\n", " ", "\t"])
        filterIndexes = Array(repeating: [], count: FilterColor.count)
        touch = Date()
        
        selectedFilters?.removeAll()
    }
    
    func updateTitle(_ newTitle: String) {
        title = newTitle
        touch = Date()
    }
}
