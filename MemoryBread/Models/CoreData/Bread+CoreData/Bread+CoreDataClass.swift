//
//  Bread+CoreDataClass.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//
//

import Foundation
import CoreData
import UIKit

@objc(Bread)
public class Bread: NSManagedObject {

    @NSManaged public private(set) var id: UUID
    @NSManaged public private(set) var createdTime: Date
    @NSManaged public var touch: Date
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var separatedContent: [String]
    @NSManaged public var filterIndexes: [[Int]]
    @NSManaged public var selectedFilters: [Int]
    @NSManaged public var folder: Folder
    
    public init(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        createdTime: Date = Date(),
        touch: Date = Date(),
        title: String,
        content: String,
        filterIndexes: [[Int]]? = nil,
        selectedFilters: [Int],
        folder: Folder
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "Bread", in: context)!
        super.init(entity: entity, insertInto: context)
        self.id = id
        self.createdTime = createdTime
        self.touch = touch
        self.title = title
        self.content = content
        self.separatedContent = content.components(separatedBy: ["\n", " ", "\t"])
        self.filterIndexes = filterIndexes ?? Array(repeating: [], count: FilterColor.count)
        self.selectedFilters = selectedFilters
        self.folder = folder
    }
    
    // 생성자 외부에 숨기기
    // refer to https://www.jessesquires.com/blog/2022/01/26/core-data-optionals/
//    @objc
//    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
//        super.init(entity: entity, insertInto: context)
//    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
//    @available(*, unavailable)
//    public init() {
//        fatalError("\(#function) not implemented")
//    }
//    
//    @available(*, unavailable)
//    public convenience init(context: NSManagedObjectContext) {
//        fatalError("\(#function) not implemented")
//    }
    
    func updateContent(with newContent: String) {
        content = newContent
        
        var contentWithNewLine = [String]()
        newContent.components(separatedBy: [" ", "\t"]).forEach {
            splitWithChar(&contentWithNewLine, for: $0, using: "\n")
        }
        separatedContent = contentWithNewLine
        
        filterIndexes = Array(repeating: [], count: FilterColor.count)
        touch = Date()
        
        selectedFilters.removeAll()
    }
    
    private func splitWithChar(_ arr: inout [String], for str: String, using char: Character) {
        guard !str.isEmpty else { return }
        var firstIndex = str.firstIndex(of: char) ?? str.endIndex
        
        if firstIndex != str.startIndex {
            arr.append(String(str[..<firstIndex]))
            splitWithChar(&arr, for: String(str[firstIndex...]), using: char)
            return
        }
        
        arr.append(String(str[firstIndex]))
        firstIndex = str.index(after: firstIndex)
        splitWithChar(&arr, for: String(str[firstIndex...]), using: char)
    }
    /// 최초 튜토리얼 세팅에만 사용해야 함.
    func updateFilterIndexes(usingIndexes indexes: [(Int, Int)]) {
        var newFilterIndexes: [[Int]] = Array(repeating: [], count: FilterColor.count)
        indexes.forEach { (index, colorIndex) in
            newFilterIndexes[colorIndex].append(index)
        }
        filterIndexes = newFilterIndexes
    }
    
    func updateFilterIndexes(with items: [WordPainter.Item]) {
        var newFilterIndexes: [[Int]] = Array(repeating: [], count: FilterColor.count)
        items.enumerated().forEach { (itemIndex, item) in
            if let colorIndex = FilterColor.colorIndex(for: item.filterColor) {
                newFilterIndexes[colorIndex].append(itemIndex)
            }
        }
        filterIndexes = newFilterIndexes
        touch = Date()
    }

    func updateTitle(_ newTitle: String) {
        title = newTitle
        touch = Date()
    }
}

// MARK: -
extension Bread {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bread> {
        return NSFetchRequest<Bread>(entityName: "Bread")
    }
}

extension Bread : Identifiable {

}

extension Bread {
    func move(to destFolder: Folder) {
        folder = destFolder
    }
}
