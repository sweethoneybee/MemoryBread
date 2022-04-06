//
//  NSManagedObjectContext+Save.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/16.
//

import CoreData

extension NSManagedObjectContext {
    func saveContextAndParentIfNeeded(forcing: Bool = false) {
        if forcing || hasChanges {
            do {
                try save()
                try parent?.save()
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveContextAndParentIfNeededThrows() throws {
        if hasChanges {
                try save()
                try parent?.save()
        }
    }
}
