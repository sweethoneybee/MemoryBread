//
//  FolderModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/23.
//

import Foundation
import CoreData

final class FolderModel {
    private let moc: NSManagedObjectContext
    private var foldersIndexChangedFlag = false
    var trashObjectID: NSManagedObjectID?
    
    init(context: NSManagedObjectContext) {
        self.moc = context
    }
   
    @discardableResult
    func createFolderWith(name: String, index: Int64) throws -> Folder {
        try isInBlackList(name)
        
        let newFolder = Folder(
            context: moc,
            name: name,
            index: index,
            breads: nil
        )
        
        do {
            try saveContextAndItsParentIfNeeded()
            return newFolder
        } catch let nserror as NSError{
            switch nserror.code {
            case NSManagedObjectConstraintMergeError:
                throw ContextSaveError.folderNameIsDuplicated
            default:
                throw ContextSaveError.unknown(nserror)
            }
        }
    }
    
    func updateFoldersIndexIfNeeded(of folderObjectIDs: [NSManagedObjectID]) {
        folderObjectIDs.enumerated().forEach { index, objectID in
            let newIndex = Int64(index)
            if let folderObject = try? moc.existingObject(with: objectID) as? Folder,
               folderObject.index != newIndex {
                folderObject.index = newIndex
                foldersIndexChangedFlag = true
            }
        }
        
        moc.perform {
            self.moc.saveContextAndParentIfNeeded()
        }
    }
    
    func isFoldersIndexChanged() -> Bool {
        return foldersIndexChangedFlag
    }
    
    func removeFoldersIndexFlag() {
        foldersIndexChangedFlag = false
    }
    
    func renameFolder(of folderObjectID: NSManagedObjectID, to newFolderName: String) throws {
        do {
            try isInBlackList(newFolderName)
            
            guard let folder = try moc.existingObject(with: folderObjectID) as? Folder else {
                fatalError("Folder casting fail")
            }
            
            
            folder.setName(newFolderName)
            do {
                try saveContextAndItsParentIfNeeded()
            } catch let nserror as NSError {
                switch nserror.code {
                case NSManagedObjectConstraintMergeError:
                    throw ContextSaveError.folderNameIsDuplicated
                default:
                    throw ContextSaveError.unknown(nserror)
                }
            }
        }
    }
    
    func delete(_ folderObjectID: NSManagedObjectID) {
        moc.perform { [moc, trashObjectID] in
            guard let folder = try? moc.existingObject(with: folderObjectID) as? Folder,
                  let allBreadsInFolder = folder.breads?.allObjects as? [Bread],
                  let trashObjectID = trashObjectID,
                  let trash = try? moc.existingObject(with: trashObjectID) as? Folder else {
                      return
                  }
            
            allBreadsInFolder.forEach {
                $0.move(to: trash)
            }
            
            moc.delete(folder)
            do {
                try self.saveContextAndItsParentIfNeeded()
            } catch {
                fatalError("Saving for deleting folder is failed.")
            }
        }
    }
    
    private func saveContextAndItsParentIfNeeded() throws {
        if moc.hasChanges {
            do {
                try moc.save()
                try moc.parent?.save()
            } catch {
                moc.parent?.rollback()
                moc.rollback()
                throw error
            }
        }
    }
    
    private func isInBlackList(_ name: String) throws {
        if FolderNameBlackList.standard.isInBlackList(name) {
            throw ContextSaveError.folderNameIsInBlackList
        }
    }
}
