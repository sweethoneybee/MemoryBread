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
        let newFolder = Folder(context: moc)
        newFolder.id = UUID()
        newFolder.name = name
        newFolder.index = index
        
        do {
            try moc.save()
            return newFolder
        } catch {
            moc.rollback()
            throw error
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
        
        moc.saveContextAndParentIfNeeded()
    }
    
    func isFoldersIndexChanged() -> Bool {
        return foldersIndexChangedFlag
    }
    
    func removeFoldersIndexFlag() {
        foldersIndexChangedFlag = false
    }
    
    func renameFolder(of folderObjectID: NSManagedObjectID, to newFolderName: String) throws {
        do {
            guard let folder = try moc.existingObject(with: folderObjectID) as? Folder else {
                fatalError("Folder casting fail")
            }
            
            folder.name = newFolderName
            do {
                try moc.save()
            } catch {
                moc.rollback()
                throw error
            }
        }
    }
    
    func delete(_ folderObjectID: NSManagedObjectID) {
        print("trashObject=\(trashObjectID)")
        moc.perform { [moc, trashObjectID] in
            guard let folder = try? moc.existingObject(with: folderObjectID) as? Folder,
                  let allBreadsInFolder = folder.breads?.allObjects as? [Bread],
                  let trashObjectID = trashObjectID,
                  let trash = try? moc.existingObject(with: trashObjectID) as? Folder else {
                      return
                  }
            
            allBreadsInFolder.forEach {
                $0.move(toTrash: trash)
            }
            
            moc.delete(folder)
            
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    fatalError("Saving for deleting folder is failed.")
                }
            }
        }
    }
}
