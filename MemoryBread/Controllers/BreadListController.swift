//
//  BreadListController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
//

import UIKit

final class BreadListController {
    struct BreadItem: Hashable {
        let title: String
        let date: Date
        let body: String
        let identifier = UUID()
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
    }
    
    var items: [BreadItem] {
        return BreadDAO.default.allBreads.map {
            BreadItem(title: $0.title ?? "",
                      date: $0.touch ?? Date.now,
                      body: $0.content ?? "")
        }
    }
}

extension BreadListController {
    func breadItem(at index: Int) -> BreadItem? {
        guard items.count > 0 && index < items.count else { return nil }
        return items[index]
    }
    
    func newBreadItem() -> BreadItem {
        let newBread = BreadDAO.default.create()
        return BreadItem(title: newBread.title ?? "",
                         date: Date.now,
                         body: newBread.content ?? "")
    }
    
    @discardableResult
    func deleteBread(at index: Int) -> Bool {
        guard let willBeDeletedBread = BreadDAO.default.bread(at: index) else {
            return false
        }
        return BreadDAO.default.delete(willBeDeletedBread)
    }
}
