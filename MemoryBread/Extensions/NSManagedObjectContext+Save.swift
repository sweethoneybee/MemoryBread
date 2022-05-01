//
//  NSManagedObjectContext+Save.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/16.
//

import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() {
        if hasChanges {
            do {
                try save()
            } catch let nserror as NSError {
                fatalError("CoreDataStack save failed: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
