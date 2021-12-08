//
//  BreadDAO.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//

import Foundation
import CoreData

extension Notification.Name {
    static let breadObjectsDidChange = Notification.Name("breadObjectsDidChange")
}

final class BreadDAO: NSObject {
    static let `default` = BreadDAO()
    
    private let context = AppDelegate.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "touch", ascending: false)]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        do {
            try controller.performFetch()
        } catch {
            fatalError("perform fetch failed")
        }
        
        controller.delegate = self
        return controller
    }()
    
    var allBreads: [Bread] {
        if let breadObjects = fetchedResultController.fetchedObjects {
            return breadObjects
        }
        return [Bread]()
    }
    
    @discardableResult
    func save() -> Bool {
        do {
            try context.save()
        } catch {
            fatalError("context save failed")
        }
        return true
    }
    
    @discardableResult
    func delete(at indexPath: IndexPath) -> Bool {
        let breadObject = fetchedResultController.object(at: indexPath)
        context.delete(breadObject)
        return true
    }
    
    func create() -> Bread {
        let bread = Bread(touch: Date(),
                          directoryName: "임시 디렉토리",
                          title: LocalizingHelper.freshBread,
                          content: "",
                          separatedContent: [],
                          filterIndexes: Array(repeating: [], count: FilterColor.count),
                          selectedFilters: nil)
        return bread
    }
    
    func bread(at indexPath: IndexPath) -> Bread {
        return fetchedResultController.object(at: indexPath)
    }
    
    func first() -> Bread? {
        return fetchedResultController.fetchedObjects?.first
    }
}

extension BreadDAO: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        NotificationCenter.default.post(name: .breadObjectsDidChange, object: nil)
    }
}

