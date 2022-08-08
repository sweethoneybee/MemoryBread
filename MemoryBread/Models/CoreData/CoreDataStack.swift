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
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: modelName)
        
        let persistentStoreDescription = container.persistentStoreDescriptions.first

        persistentStoreDescription?.shouldMigrateStoreAutomatically = true
        persistentStoreDescription?.shouldInferMappingModelAutomatically = false
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
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
            let result: Array<NSManagedObjectID> = try viewContext.fetch(fr)
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
    func writeAndSaveIfHasChanges(block: @escaping (NSManagedObjectContext) -> ()) {
        persistentContainer.performBackgroundTask { context in
            context.perform {
                block(context)
                context.saveIfNeeded()
            }
        }
    }
}
