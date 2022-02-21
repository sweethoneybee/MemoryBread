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
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var separatedContent: [String]?
    @NSManaged public var filterIndexes: [[Int]]?
    @NSManaged public var selectedFilters: [Int]?
    @NSManaged public var folders: NSSet?
}

// MARK: Generated accessors for breads
extension Bread {

    @objc(addFoldersObject:)
    @NSManaged public func addToFolders(_ value: Folder)

    @objc(removeFoldersObject:)
    @NSManaged public func removeFromFolders(_ value: Folder)

    @objc(addFolders:)
    @NSManaged public func addToFolders(_ values: NSSet)

    @objc(removeFolders:)
    @NSManaged public func removeFromFolders(_ values: NSSet)

}

extension Bread : Identifiable {

}

extension Bread {
    var currentFolder: Folder? {
        guard let folders = folders?.allObjects as? [Folder] else {
            return nil
        }
        
        return folders.filter {
            $0.pinnedAtTop != true
        }.first
    }
    
    func move(toTrash trash: Folder) {
        guard let folders = folders else { return }
        removeFromFolders(folders)
        addToFolders(trash)
    }
    
    func move(from src: Folder, to dest: Folder) {
        removeFromFolders(src)
        addToFolders(dest)
    }
    
    func move(to dest: Folder, root: Folder) {
        guard let folders = folders else { return }
        removeFromFolders(folders)
        addToFolders(dest)
        addToFolders(root)
    }
}

extension Bread {
    static func makeBasicBread(context: NSManagedObjectContext) -> Bread {
        return Bread(
            context: context,
            touch: Date(),
            title: LocalizingHelper.freshBread,
            content: "",
            separatedContent: [],
            filterIndexes: Array(repeating: [], count: FilterColor.count),
            selectedFilters: nil
        )
    }
    
    static func makeBread(context: NSManagedObjectContext, title: String, content: String) -> Bread {
        let bread = Bread.makeBasicBread(context: context)
        bread.updateTitle(title)
        bread.updateContent(with: content)
        return bread
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
    
    func updateContent(with newContent: String) {
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
