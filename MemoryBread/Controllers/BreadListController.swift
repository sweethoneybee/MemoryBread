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

        func hash(into hasher: inout Hasher) {
            hasher.combine(date)
        }
    }
    
    var items: [BreadItem] {
        return BreadDAO.default.allBreads
            .map {
                BreadItem(title: $0.title ?? "",
                          date: $0.touch ?? Date.now,
                          body: $0.content ?? "")
            }
    }
    
    var breadItemsDidChange: (([BreadItem]) -> (Void))?
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(breadObjectDidChange), name: .breadObjectsDidChange, object: nil)
    }
}

extension BreadListController {
    func createBread() -> Bread {
        return BreadDAO.default.create()
    }
    
    func bread(at indexPath: IndexPath) -> Bread {
        return BreadDAO.default.bread(at: indexPath)
    }
    
    @discardableResult
    func deleteBread(at indexPath: IndexPath) -> Bool {
        return BreadDAO.default.delete(at: indexPath)
    }
}

extension BreadListController {
    @objc
    func breadObjectDidChange() {
        breadItemsDidChange?(items)
    }
}
