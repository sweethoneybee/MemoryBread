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
    
    lazy var viewContext: NSManagedObjectContext = {
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return persistentContainer.viewContext
    }()
    
    lazy var writeContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: modelName)
        
        let persistentStoreDescription = container.persistentStoreDescriptions.first
        persistentStoreDescription?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        persistentStoreDescription?.setOption(false as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private var notificationTokens: [NSObjectProtocol] = []
    
    init(modelName: String) {
        self.modelName = modelName
        
        let writeNotiToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: writeContext, queue: nil) { notificaation in
            self.viewContext.mergeChanges(fromContextDidSave: notificaation)
        }
        notificationTokens.append(writeNotiToken)
    }
    
    deinit  {
        notificationTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }
}

// MARK: - Internal
extension CoreDataStack {
    func deleteAndSaveObjects(of objectIDs: [NSManagedObjectID]) {
        let context = writeContext
        context.perform {
            objectIDs.forEach { id in
                let object = context.object(with: id)
                context.delete(object)
            }
            do {
                try context.save()
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func writeAndSaveIfHasChanges(block: @escaping (NSManagedObjectContext) -> ()) {
        let context = writeContext
        context.perform {
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch let nserror as NSError {
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    func makeChildMainQueueContext() -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = writeContext
        return childContext
    }
}
