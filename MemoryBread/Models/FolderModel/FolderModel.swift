//
//  FolderModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/23.
//

import Foundation
import CoreData

final class FolderModel {
    private var foldersIndexChangedFlag = false

    private let coreDataStack: CoreDataStack
    var container: NSPersistentContainer { coreDataStack.persistentContainer }
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
   
    @discardableResult
    func createFolderWith(name: String, index: Int64) throws -> NSManagedObjectID {
        try isInBlackList(name)
        
        var result: NSManagedObjectID?
        var saveError: ContextSaveError? = nil
        let writeContext = container.newBackgroundContext()
        writeContext.performAndWait {
            let newFolder = Folder(
                context: writeContext,
                name: name,
                index: index,
                breads: nil
            )
            
            do {
                try writeContext.save()
                result = newFolder.objectID
            } catch let nserror as NSError{
                writeContext.rollback()
                switch nserror.code {
                case NSManagedObjectConstraintMergeError:
                    saveError = ContextSaveError.folderNameIsDuplicated
                default:
                    saveError = ContextSaveError.unknown(nserror)
                }
            }
        }
        
        if let saveError = saveError {
            throw saveError
        }
        return result!
    }
    
    func updateFoldersIndexIfNeeded(of folderObjectIDs: [NSManagedObjectID]) {
        let viewContext = container.viewContext
        viewContext.performAndWait {
            folderObjectIDs.enumerated().forEach { index, objectID in
                let newIndex = Int64(index)
                if let folderObject = try? viewContext.existingObject(with: objectID) as? Folder,
                   folderObject.index != newIndex {
                    folderObject.index = newIndex
                    foldersIndexChangedFlag = true
                }
            }
            
            viewContext.perform {
                viewContext.saveIfNeeded()
            }
        }
    }
    
    func isFoldersIndexChanged() -> Bool {
        return foldersIndexChangedFlag
    }
    
    func removeFoldersIndexFlag() {
        foldersIndexChangedFlag = false
    }
    
    func renameFolder(of folderObjectID: NSManagedObjectID, to newFolderName: String) throws {
        try isInBlackList(newFolderName)
        
        var saveError: ContextSaveError?
        let writeContext = container.newBackgroundContext()
        writeContext.performAndWait {
            guard let folder = writeContext.object(with: folderObjectID) as? Folder else {
                fatalError("Folder casting fail")
            }
            
            folder.setName(newFolderName)
            do {
                try writeContext.save()
            } catch let nserror as NSError {
                writeContext.rollback()
                switch nserror.code {
                case NSManagedObjectConstraintMergeError:
                    saveError = ContextSaveError.folderNameIsDuplicated
                default:
                    saveError = ContextSaveError.unknown(nserror)
                }
            }
        }
        
        if let saveError = saveError {
            throw saveError
        }
    }
    
    func delete(_ folderObjectID: NSManagedObjectID) {
        let trashObjectID = coreDataStack.trashFolderObjectID
        let writeContext = container.newBackgroundContext()
        writeContext.perform {
            guard let folder = try? writeContext.existingObject(with: folderObjectID) as? Folder,
                  let allBreadsInFolder = folder.breads?.allObjects as? [Bread],
                  let trash = try? writeContext.existingObject(with: trashObjectID) as? Folder else {
                      return
                  }
            
            allBreadsInFolder.forEach {
                $0.move(to: trash)
            }
            
            writeContext.delete(folder)
            writeContext.saveIfNeeded()
        }
    }
    
    private func isInBlackList(_ name: String) throws {
        if FolderNameBlackList.standard.isInBlackList(name) {
            throw ContextSaveError.folderNameIsInBlackList
        }
    }
}
