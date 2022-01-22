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
        
        var folderWithAllBreadsInstance: NSManagedObject!
        
        // '모든 암기빵' 폴더 생성 및 기존 암기빵들과 관계 맺어주기
        let fetchRequestForFolderWithAllBreads = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
        fetchRequestForFolderWithAllBreads.predicate = NSPredicate(format: "orderingNumber = %lld", Int64.max)
        let resultsForFolderWithAllBreads = try manager.destinationContext.fetch(fetchRequestForFolderWithAllBreads)
        
        if let resultInstance = resultsForFolderWithAllBreads.last as? NSManagedObject {
            folderWithAllBreadsInstance = resultInstance
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
            folderWithAllBreadsInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)

            folderWithAllBreadsInstance.setValue(UUID(), forKey: "id")
            folderWithAllBreadsInstance.setValue(LocalizingHelper.allMemoryBreads, forKey: "name")
            folderWithAllBreadsInstance.setValue(Int64.max, forKey: "orderingNumber")
        }
    
        let relationshipSet = dInstance.mutableSetValue(forKey: "folders")
        relationshipSet.add(folderWithAllBreadsInstance!)
        
        // '휴지통' 폴더 생성
        let fetchRequestForTrash = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")
        fetchRequestForTrash.predicate = NSPredicate(format: "orderingNumber = %lld", 0)
        let resultsForTrash = try manager.destinationContext.fetch(fetchRequestForTrash)
        
        if (resultsForTrash.last as? NSManagedObject) == nil {
            let entity = NSEntityDescription.entity(forEntityName: "Folder", in: manager.destinationContext)!
            let trashInstance = NSManagedObject(entity: entity, insertInto: manager.destinationContext)
            
            trashInstance.setValue(UUID(), forKey: "id")
            trashInstance.setValue(LocalizingHelper.trash, forKey: "name")
            trashInstance.setValue(0, forKey: "orderingNumber")
        }
    }
}
