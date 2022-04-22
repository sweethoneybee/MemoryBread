//
//  MoveBreadModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/11.
//

import Foundation
import CoreData

final class MoveBreadModel {
    
    typealias Item = MoveFolderListCell.Item
    
    private let moc: NSManagedObjectContext
    private let selectedBreadObjectIDs: [NSManagedObjectID]
    private let shouldDisabledFolderObjectID: NSManagedObjectID?
    
    private let folderModel: FolderModel
    
    private lazy var selectedBreads: [Bread] = {
        var result: [Bread]?
        moc.performAndWait {
            result = selectedBreadObjectIDs.compactMap { objectID in
                moc.object(with: objectID) as? Bread
            }
        }
        return result ?? []
    }()
    
    lazy var selectedBreadNames: [String] = {
        var result: [String]?
        moc.performAndWait {
            result = selectedBreads.compactMap { $0.title }
        }
        return result ?? []
    }()
    
    private lazy var foldersFetchRequest: NSFetchRequest<Folder> = {
        let fr = Folder.fetchRequest()
        
        let notSystemFolder = NSPredicate(format: "isSystemFolder = NO")
        fr.predicate = notSystemFolder
        fr.shouldRefreshRefetchedObjects = true
        let pinnedAtTopSort = NSSortDescriptor(key: "pinnedAtTop", ascending: false)
        let orderingIndexSort = NSSortDescriptor(key: "index", ascending: true)
        fr.sortDescriptors = [pinnedAtTopSort, orderingIndexSort]
        
        return fr
    }()
    
    private lazy var folders: [Folder] = {
        var result: [Folder]?
        moc.performAndWait {
            result = try? moc.fetch(foldersFetchRequest)
        }
        return result ?? []
    }()
    
    private var createdFolderCount = 0
    
    var didCreateFolderHandler: ((Item) -> Void)?
    
    // MARK: - init
    init(
        context: NSManagedObjectContext,
        selectedBreadObjectIDs: [NSManagedObjectID],
        shouldDisabledFolderObjectID: NSManagedObjectID?
    ) {
        self.moc = context
        self.selectedBreadObjectIDs = selectedBreadObjectIDs
        self.shouldDisabledFolderObjectID = shouldDisabledFolderObjectID
        
        self.folderModel = FolderModel(context: context)
    }
}

// MARK: - 폴더 목록 조회 관련
extension MoveBreadModel {
    func makeFolderItems() -> [Item] {
        var items: [Item]?
        moc.performAndWait {
            items = folders.map {
                Item(
                    name: $0.localizedName,
                    disabled: ($0.objectID == shouldDisabledFolderObjectID) ? true : false,
                    objectID: $0.objectID
                )
            }
        }
        return items ?? []
    }
}

// MARK: - 옮기기 로직
extension MoveBreadModel {
    func moveBreads(to destObjectID: NSManagedObjectID) {
        moc.perform {
            guard let destFolder = self.moc.object(with: destObjectID) as? Folder else {
                return
            }
        
            self.moveSelectedBreads(to: destFolder)
            self.moc.saveContextAndParentIfNeeded()
        }
    }

    private func moveSelectedBreads(to dest: Folder) {
        selectedBreads.forEach {
            $0.move(to: dest)
        }
    }
}

// MARK: - 폴더 생성
extension MoveBreadModel {
    private var foldersFirstIndex: Int64 {
        var index: Int64?
        moc.performAndWait {
            index = self.folders.first?.index
        }
        return index ?? 1
    }
    
    private var foldersCount: Int {
        var count: Int?
        moc.performAndWait {
            count = self.folders.count
        }
        return count ?? 0
    }
    
    func createFolder(withName name: String) throws {
        let topIndex = foldersFirstIndex
        let newIndex = topIndex - Int64(foldersCount + createdFolderCount)
        createdFolderCount += 1
        do {
            let folderID = try folderModel.createFolderWith(name: name, index: newIndex)
            let newFolderItem = Item(
                name: name,
                disabled: false,
                objectID: folderID
            )
            didCreateFolderHandler?(newFolderItem)
        } catch {
            throw error
        }
    }
}
