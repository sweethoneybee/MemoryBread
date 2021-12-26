//
//  BreadDAO.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//

import Foundation
import CoreData

final class BreadDAO: NSObject {
    init(context: NSManagedObjectContext = AppDelegate.viewContext) {
        self.context = context
    }

    private let context: NSManagedObjectContext

    func saveIfNeeded() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
    }
    
    func create() -> Bread {
        let bread = Bread(touch: Date(),
                          directoryName: "기본",
                          title: LocalizingHelper.freshBread,
                          content: "",
                          separatedContent: [],
                          filterIndexes: Array(repeating: [], count: FilterColor.count),
                          selectedFilters: nil,
                          context: context)
        return bread
    }
}
