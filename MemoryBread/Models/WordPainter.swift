//
//  WordItemModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/20.
//

import UIKit
import Foundation
import CoreData

final class WordPainter {
    struct Item: Identifiable {
        let id = UUID()
        let word: String
        var filterColor: UIColor? {
            didSet {
                isFiltered = false
            }
        }
        var isFiltered: Bool = false {
            didSet {
                isPeeking = false
            }
        }
        var isPeeking: Bool = false
        
        init(word: String) {
            self.word = word
        }
    }

    // MARK: - Models
    private let bread: Bread
    private let managedObjectContext: NSManagedObjectContext
    
    /// items는 오직 순서를 위해서만 사용함; 값의 최신화를 보장하지 않음.
    private lazy var items: [Item] = populateItems()
    private lazy var itemsWithKey: [UUID: Item] = {
        return Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }()
    
    // MARK: - Life Cycle
    init(context: NSManagedObjectContext, bread: Bread) {
        self.managedObjectContext = context
        self.bread = bread
    }
    
    convenience init(_ model: WordPainter, context: NSManagedObjectContext) {
        self.init(context: context, bread: model.bread)
        self.items = model.items
        self.itemsWithKey = model.itemsWithKey
    }
    
    // MARK: - 쿼리
    var count: Int {
        return items.count
    }
    
    func itemHasFilter(forKey key: UUID) -> Bool {
        return itemsWithKey[key]?.filterColor != nil ? true : false
    }
    
    func item(forKey key: UUID) -> Item? {
        return itemsWithKey[key]
    }
    
    func ColorIndex(forKey key: UUID) -> Int? {
        return FilterColor.colorIndex(for: itemsWithKey[key]?.filterColor)
    }
    
    func ids() -> [UUID] {
        return items.map { $0.id }
    }
    
    func idsHavingFilter() -> [UUID] {
        return itemsWithKey
            .filter { $1.filterColor != nil }
            .map { id, _ in
                return id
            }
    }
    
    // MARK: - 명령
    func removeFilterOfItem(forKey key: UUID) {
        itemsWithKey[key]?.filterColor = nil
    }
    
    func setFilterOfItem(forKey key: UUID, to filterColor: UIColor?, isFiltered: Bool) {
        itemsWithKey[key]?.filterColor = filterColor
        itemsWithKey[key]?.isFiltered = isFiltered
    }

    func togglePeekingOfItem(forKey key: UUID) {
        itemsWithKey[key]?.isPeeking.toggle()
    }
    
    func updateFilterOfItems(using filterValue: Int, isFiltered: Bool) -> [UUID] {
        var updatedKeys: [UUID] = []
        bread.filterIndexes?[filterValue].forEach {
            let id = items[$0].id
            itemsWithKey[id]?.isFiltered = isFiltered
            updatedKeys.append(items[$0].id)
        }
        return updatedKeys
    }
    
    func saveBreadFilterIndexes() {
        bread.updateFilterIndexes(with: items.map {
            var item = Item(word: $0.word)
            item.filterColor = itemsWithKey[$0.id]?.filterColor
            return item
        })
        try? managedObjectContext.save()
    }
    
    /// Bread's content has changed equally as `newContent`
    func refreshItems() {
        self.items = self.populateItems()
        self.itemsWithKey = Dictionary(uniqueKeysWithValues: self.items.map { ($0.id, $0) })
    }
    
    private func populateItems() -> [Item] {
        guard let separatedContent = bread.separatedContent,
              let filterIndexes = bread.filterIndexes else {
                  return []
              }
        
        var items = separatedContent.map { Item(word: $0) }
        
        filterIndexes.enumerated().forEach { (filterValue, wordIndexes) in
            wordIndexes.forEach {
                items[$0].filterColor = FilterColor(rawValue: filterValue)?.color()
            }
        }
        
        return items
    }
}