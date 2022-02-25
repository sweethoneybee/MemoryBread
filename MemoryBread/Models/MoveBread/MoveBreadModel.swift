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
    private let currentFolderObjectID: NSManagedObjectID
    private let rootObjectID: NSManagedObjectID
    private let trashObjectID: NSManagedObjectID
    
    private let folderModel: FolderModel
    
    private lazy var currentFolcerObject: Folder = {
        guard let currentFolder = moc.object(with: currentFolderObjectID) as? Folder else {
            fatalError("Folder casting error")
        }
        return currentFolder
    }()
    
    private lazy var rootObject: Folder = {
        guard let root = moc.object(with: rootObjectID) as? Folder else {
            fatalError("Folder casting error")
        }
        return root
    }()
    
    private lazy var trashObject: Folder = {
        guard let trash = moc.object(with: trashObjectID) as? Folder else {
            fatalError("Folder casting error")
        }
        return trash
    }()
    
    private lazy var selectedBreads: [Bread] = {
        selectedBreadObjectIDs.compactMap { objectID in
            moc.object(with: objectID) as? Bread
        }
    }()
    
    private lazy var selectedBreadNames: [String] = {
        selectedBreads.compactMap { $0.title }
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
        currentFolderObjectID: NSManagedObjectID,
        rootObjectID: NSManagedObjectID,
        trashObjectID: NSManagedObjectID
    ) {
        self.moc = context
        self.selectedBreadObjectIDs = selectedBreadObjectIDs
        self.currentFolderObjectID = currentFolderObjectID
        self.rootObjectID = rootObjectID
        self.trashObjectID = trashObjectID
        
        self.folderModel = FolderModel(context: context)
    }
}

// MARK: - 폴더 목록 조회 관련
extension MoveBreadModel {
    func selectedBreadNames(inWidth maxWidth: CGFloat, withAttributes attributes: [NSAttributedString.Key : Any]) -> String {
        guard let lastName = selectedBreadNames.last else {
            return LocalizingHelper.noSelectedMemoryBread
        }
        
        let connectedNames = selectedBreadNames.reduce("") { partialResult, nextName in
            if partialResult.isEmpty {
                return nextName
            }
            return partialResult + ", \(nextName)"
        }
        
        if connectedNames.size(withAttributes: attributes).width < maxWidth {
            return connectedNames
        }
        
        let trailingText = selectedBreads.count != 1 ? " " + String(format: LocalizingHelper.andTheNumberOfBreads, selectedBreadNames.count) : ""
        let omittedNames = lastName + trailingText
        if omittedNames.size(withAttributes: attributes).width < maxWidth {
            return omittedNames
        }
        
        let trimmedNames = iterateTrimmingSuffix(
            lastName,
            trailingBy: trailingText,
            inWidth: maxWidth,
            withAttributes: attributes
        )
        return trimmedNames
    }
    
    private func iterateTrimmingSuffix(
        _ text: String,
        trailingBy trailingText: String,
        inWidth maxWidth: CGFloat,
        withAttributes attributes: [NSAttributedString.Key : Any]
    ) -> String {
        var trimmedText = text
        var resultText = trimmedText + "..." + trailingText
        while resultText.size(withAttributes: attributes).width >= maxWidth,
              trimmedText.isEmpty != true {
            _ = trimmedText.popLast()
            resultText = trimmedText + "..." + trailingText
        }
        
        return resultText
    }
    
    func selectedBreadsCount() -> String {
        return String(format: LocalizingHelper.selectedTheNumberOfMemoryBreads, selectedBreadNames.count)
    }
    
    var folderItems: [Item] {
        folders.map {
            Item(
                name: $0.name ?? "",
                disabled: ($0.objectID == currentFolderObjectID) ? true : false,
                objectID: $0.objectID
            )
        }
    }
}

// MARK: - 옮기기 로직
extension MoveBreadModel {
    func moveBreads(to destObjectID: NSManagedObjectID) {
        guard let destFolder = moc.object(with: destObjectID) as? Folder else {
            return
        }
        
        if isInTrash() {
            moveFromTrash(to: destFolder)
            moc.saveContextAndParentIfNeeded()
            return
        }
        
        if isInRoot() {
            moveFromRoot(to: destFolder)
            moc.saveContextAndParentIfNeeded()
            return
        }
        
        moveSelectedBreads(from: currentFolcerObject, to: destFolder)
        moc.saveContextAndParentIfNeeded()
    }
 
    private func isInTrash() -> Bool {
        return currentFolderObjectID == trashObjectID
    }
    
    private func isInRoot() -> Bool {
        return currentFolderObjectID == rootObjectID
    }
    
    private func moveFromTrash(to dest: Folder) {
        selectedBreads.forEach {
            $0.addToFolders(rootObject)
            $0.move(from: trashObject, to: dest)
        }
    }

    private func moveFromRoot(to dest: Folder) {
        selectedBreads.forEach {
            $0.move(to: dest, root: rootObject)
        }
    }

    private func moveSelectedBreads(from src: Folder, to dest: Folder) {
        selectedBreads.forEach {
            $0.move(from: src, to: dest)
        }
    }
}

// MARK: - 폴더 생성
extension MoveBreadModel {
    func createFolder(withName name: String) throws {
        let topIndex = folders.first?.index ?? 0
        let newIndex = topIndex + 1
        do {
            try folderModel.createFolderWith(name: name, index: newIndex)
        } catch {
            throw error
        }
    }
}
