//
//  MoveBreadModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/11.
//

import Foundation
import CoreData

final class MoveBreadModel {
    private let moc: NSManagedObjectContext
    private let selectedBreadObjectIDs: [NSManagedObjectID]
    private let currentFolderObjectID: NSManagedObjectID?
    
    private lazy var selectedBreads: [Bread] = {
        selectedBreadObjectIDs.compactMap { objectID in
            moc.object(with: objectID) as? Bread
        }
    }()
    
    private lazy var foldersFetchRequest: NSFetchRequest<Folder> = {
        let fr = Folder.fetchRequest()
        
        let notPinned = NSPredicate(format: "pinnedAtTop == NO && pinnedAtBottom == NO")
        fr.predicate = notPinned
        let orderingIndexSort = NSSortDescriptor(key: "index", ascending: true)
        fr.sortDescriptors = [orderingIndexSort]
        
        return fr
    }()
    
    private lazy var folders: [Folder] = {
        (try? moc.fetch(foldersFetchRequest)) ?? []
    }()
    
    init(
        context: NSManagedObjectContext,
        selectedBreadObjectIDs: [NSManagedObjectID],
        currentFolderObjectID: NSManagedObjectID?
    ) {
        self.moc = context
        self.selectedBreadObjectIDs = selectedBreadObjectIDs
        self.currentFolderObjectID = currentFolderObjectID
    }
}

extension MoveBreadModel {
    var selectedBreadNames: [String] {
        selectedBreads.compactMap { $0.title }
    }
    
    var folderInfos: [FolderItem] {
        folders.map {
            FolderItem(
                name: $0.name ?? "",
                disabled: ($0.objectID == currentFolderObjectID) ? true : false
            )
        }
    }
    
    struct FolderItem: Hashable {
        let name: String
        let disabled: Bool
        let id = UUID()
    }
}
