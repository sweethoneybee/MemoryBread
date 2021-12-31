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
        return persistentContainer.viewContext
    }
    
    lazy var writeContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()
    
    lazy var deleteContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
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
    
    private var notificationTokens: [NSObjectProtocol] = []
    
    init(modelName: String) {
        self.modelName = modelName
        
        let writeNotiToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: writeContext, queue: nil) { notificaation in
            self.viewContext.mergeChanges(fromContextDidSave: notificaation)
        }
        notificationTokens.append(writeNotiToken)
        let deleteNotiToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: deleteContext, queue: nil) { notificaation in
            self.viewContext.mergeChanges(fromContextDidSave: notificaation)
        }
        notificationTokens.append(deleteNotiToken)
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
        let deleteContext = deleteContext
        deleteContext.perform {
            objectIDs.forEach { id in
                let object = deleteContext.object(with: id)
                deleteContext.delete(object)
            }
            do {
                try deleteContext.save()
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
