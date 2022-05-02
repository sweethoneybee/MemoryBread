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

    private let coreDataStack: CoreDataStack
    private let selectedBreadObjectIDs: [NSManagedObjectID]
    private let shouldDisabledFolderObjectID: NSManagedObjectID?
    
    private let folderModel: FolderModel
    
    private var container: NSPersistentContainer { coreDataStack.persistentContainer }
    private var viewContext: NSManagedObjectContext { container.viewContext }
    
    private lazy var selectedBreads: [Bread] = {
        selectedBreadObjectIDs.compactMap { objectID in
            viewContext.object(with: objectID) as? Bread
        }
    }()
    
    lazy var selectedBreadNames: [String] = {
        selectedBreads.compactMap { $0.title }
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
        (try? viewContext.fetch(foldersFetchRequest)) ?? []
    }()
    
    private var createdFolderCount = 0
    
    var didCreateFolderHandler: ((Item) -> Void)?
    
    // MARK: - init
    init(
        coreDataStack: CoreDataStack,
        selectedBreadObjectIDs: [NSManagedObjectID],
        shouldDisabledFolderObjectID: NSManagedObjectID?
    ) {
        self.coreDataStack = coreDataStack
        self.selectedBreadObjectIDs = selectedBreadObjectIDs
        self.shouldDisabledFolderObjectID = shouldDisabledFolderObjectID
        self.folderModel = FolderModel(coreDataStack: coreDataStack)
    }
}

// MARK: - 폴더 목록 조회 관련
extension MoveBreadModel {
    func makeFolderItems() -> [Item] {
        folders.map {
            Item(
                name: $0.localizedName,
                disabled: ($0.objectID == shouldDisabledFolderObjectID) ? true : false,
                objectID: $0.objectID
            )
        }
    }
}

// MARK: - 옮기기 로직
extension MoveBreadModel {
    func moveBreads(to destObjectID: NSManagedObjectID) {
        let writeContext = container.newBackgroundContext()
        writeContext.perform {
            guard let destFolder = writeContext.object(with: destObjectID) as? Folder else {
                return
            }
        
            let targetBreads = self.selectedBreadObjectIDs.compactMap {
                try? writeContext.existingObject(with: $0) as? Bread
            }
            for bread in targetBreads {
                bread.move(to: destFolder)
            }
            
            writeContext.saveIfNeeded()
        }
    }
}

// MARK: - 폴더 생성
extension MoveBreadModel {
    private var secondFolderIndex: Int64 {
        folders[safe: 1]?.index ?? 1
    }
    
    func createFolder(withName name: String) throws {
        // 위에서 두 번째 위치에 새로운 Folder가 삽입되도록 index 계산
        let newIndex = secondFolderIndex - Int64(createdFolderCount + 1)
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
