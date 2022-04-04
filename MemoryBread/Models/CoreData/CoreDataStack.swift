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
        let context = makeChildMainQueueContext()
        context.automaticallyMergesChangesFromParent = true
        return context
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
    
    lazy var defaultFolderObjectID: NSManagedObjectID = fetchFolderObjectID(of: UserManager.defaultFolderID)
    lazy var trashFolderObjectID: NSManagedObjectID = fetchFolderObjectID(of: UserManager.trashFolderID)

    private func fetchFolderObjectID(of id: String) -> NSManagedObjectID {
        guard let folderID = UUID(uuidString: id) else {
            fatalError("UUIDString casting failed")
        }
        let fr: NSFetchRequest<NSManagedObjectID> = NSFetchRequest(entityName: "Folder")
        fr.resultType = .managedObjectIDResultType
        fr.predicate = NSPredicate(format: "id = %@", folderID as CVarArg)
        do {
            let result: Array<NSManagedObjectID> = try writeContext.fetch(fr)
            guard let objectID = result.first else {
                fatalError("Folder fetching has no results.")
            }
            return objectID
        } catch {
            fatalError("Folder fetching has failed.")
        }
    }
    
    init(modelName: String) {
        self.modelName = modelName
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
            context.saveContextAndParentIfNeeded()
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
    
    func makeChildConcurrencyQueueContext() -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = writeContext
        return childContext
    }
}
