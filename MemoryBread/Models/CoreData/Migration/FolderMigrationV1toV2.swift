//
//  FolderMigrationV1toV2.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/22.
//

import Foundation
import CoreData

class FolderMigrationV1toV2: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)
         
        // '모든 암기빵' 폴더 생성
        let fetchRequestForFolderWithAllBreads = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
        fetchRequestForFolderWithAllBreads.predicate = NSPredicate(format: "index = %lld", 0)
        let resultsForFolderWithAllBreads = try manager.destinationContext.fetch(fetchRequestForFolderWithAllBreads)
            
        if (resultsForFolderWithAllBreads.last as? NSManagedObject) == nil {
            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
            let folderWithAllBreadsInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)

            folderWithAllBreadsInstance.setValue(UUID(), forKey: "id")
            folderWithAllBreadsInstance.setValue(LocalizingHelper.allMemoryBreads, forKey: "name")
            folderWithAllBreadsInstance.setValue(0, forKey: "index")
            folderWithAllBreadsInstance.setValue(true, forKey: "pinnedAtTop")
            folderWithAllBreadsInstance.setValue(true, forKey: "isSystemFolder")
        }
        
        
        // '암기빵' 기본 폴더 생성 및 기존 암기빵들과 관계 맺어주기
        var defaultFolderInstance: NSManagedObject!
        
        let fetchRequestForDefaultFolder = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
        fetchRequestForDefaultFolder.predicate = NSPredicate(format: "index = %lld", 1)
        let resultsForDefaultFolder = try manager.destinationContext.fetch(fetchRequestForDefaultFolder)
        
        if let resultInstance = resultsForDefaultFolder.last as? NSManagedObject {
            defaultFolderInstance = resultInstance
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
            defaultFolderInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)
            
            let defaultFolderID = UUID(uuidString: UserManager.defaultFolderID)!
            defaultFolderInstance.setValue(defaultFolderID, forKey: "id")
            defaultFolderInstance.setValue(LocalizingHelper.appTitle, forKey: "name")
            defaultFolderInstance.setValue(1, forKey: "index")
            defaultFolderInstance.setValue(true, forKey: "pinnedAtTop")
        }
        
        dInstance.setValue(defaultFolderInstance, forKey: "folder")
        
        
        // '휴지통' 폴더 생성
        let fetchRequestForTrash = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
        fetchRequestForTrash.predicate = NSPredicate(format: "index = %lld", 2)
        let resultsForTrash = try manager.destinationContext.fetch(fetchRequestForTrash)
        
        if (resultsForTrash.last as? NSManagedObject) == nil {
            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
            let trashInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)
            
            let trashFolderID = UUID(uuidString: UserManager.trashFolderID)!
            trashInstance.setValue(trashFolderID, forKey: "id")
            trashInstance.setValue(LocalizingHelper.trash, forKey: "name")
            trashInstance.setValue(2, forKey: "index")
            trashInstance.setValue(true, forKey: "pinnedAtBottom")
            trashInstance.setValue(true, forKey: "isSystemFolder")
        }
    }
    
//    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
//        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)
//
//        var folderWithAllBreadsInstance: NSManagedObject!
//
//        // '모든 암기빵' 폴더 생성 및 기존 암기빵들과 관계 맺어주기
//        let fetchRequestForFolderWithAllBreads = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
//        fetchRequestForFolderWithAllBreads.predicate = NSPredicate(format: "index = %lld", 0)
//        let resultsForFolderWithAllBreads = try manager.destinationContext.fetch(fetchRequestForFolderWithAllBreads)
//
//        if let resultInstance = resultsForFolderWithAllBreads.last as? NSManagedObject {
//            folderWithAllBreadsInstance = resultInstance
//        } else {
//            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
//            folderWithAllBreadsInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)
//
//            folderWithAllBreadsInstance.setValue(UUID(), forKey: "id")
//            folderWithAllBreadsInstance.setValue(LocalizingHelper.allMemoryBreads, forKey: "name")
//            folderWithAllBreadsInstance.setValue(0, forKey: "index")
//            folderWithAllBreadsInstance.setValue(true, forKey: "pinnedAtTop")
//        }
//
//        let relationshipSet = dInstance.mutableSetValue(forKey: "folders")
//        relationshipSet.add(folderWithAllBreadsInstance!)
//
//        // '휴지통' 폴더 생성
//        let fetchRequestForTrash = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
//        fetchRequestForTrash.predicate = NSPredicate(format: "index = %lld", 1)
//        let resultsForTrash = try manager.destinationContext.fetch(fetchRequestForTrash)
//
//        if (resultsForTrash.last as? NSManagedObject) == nil {
//            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
//            let trashInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)
//
//            trashInstance.setValue(UUID(), forKey: "id")
//            trashInstance.setValue(LocalizingHelper.trash, forKey: "name")
//            trashInstance.setValue(1, forKey: "index")
//            trashInstance.setValue(true, forKey: "pinnedAtBottom")
//        }
//    }
}
