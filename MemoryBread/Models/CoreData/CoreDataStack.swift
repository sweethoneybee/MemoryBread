//
//  CoreDataStack.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/28.
//

import CoreData

/// Refer to
/// https://www.raywenderlich.com/7586-multiple-managed-object-contexts-with-core-data-tutorial
final class CoreDataStack {
    
    private let modelName: String
    
    lazy var mainContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    init(modelName: String) {
        self.modelName = modelName
    }
}

// MARK: - Internal
extension CoreDataStack {
    
    func saveContext() {
        guard mainContext.hasChanges else { return }
        
        do {
            try mainContext.save()
        } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func makeChildContextOfMainContext() -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = mainContext
        return childContext
    }
}
