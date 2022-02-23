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
    
    init(context: NSManagedObjectContext) {
        self.moc = context
    }
    
    func createFolderWith(name: String, index: Int64) throws {
        let newFolder = Folder(context: moc)
        newFolder.id = UUID()
        newFolder.name = name
        newFolder.index = index
        
        do {
            try moc.save()
        } catch {
            moc.delete(newFolder)
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
}
