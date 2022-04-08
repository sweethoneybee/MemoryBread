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
                parent?.perform {
                    self.parent?.saveContextAndParentIfNeeded(forcing: forcing)
                }
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveContextAndParentIfNeededThrows() throws {
        if hasChanges {
            try save()
            
            if parent?.hasChanges ?? false {
                parent?.perform {
                    do {
                        try self.parent?.save()
                    } catch let nserror as NSError {
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            }
        }
    }
}
