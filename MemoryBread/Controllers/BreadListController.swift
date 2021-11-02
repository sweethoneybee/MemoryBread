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
    
    lazy var breads: [Bread] = {
        return BreadDAO().fetchAll()
    }()
    
    // TODO: 이렇게 해도 될지, 계속 업데이트 시킬지 개선사항 찾아볼 것
    var items: [BreadItem] {
        return fetchItems()
//        return internalItems()
    }
}

extension BreadListController {
    func fetchItems() -> [BreadItem] {
        return breads.map {
            BreadItem(title: $0.title ?? "",
                          date: $0.touch ?? Date.now,
                          body: $0.content ?? "")
        }
    }
    
    func getBread(at index: Int) -> Bread {
        return breads[index]
    }
    
    func createBread() -> BreadItem {
        let newBread = BreadDAO().create()
        breads.insert(newBread, at: 0)
        return BreadItem(title: newBread.title ?? "",
                         date: newBread.touch ?? Date.now,
                         body: newBread.content ?? "")
    }
    
    func deleteBread(at index: Int) {
        let dao = BreadDAO()
        dao.delete(breads[index])
        dao.save()
        breads.remove(at: index)
    }
}
