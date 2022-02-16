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
    private let prefixTrimmingLength = 15
    
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
        currentFolderObjectID: NSManagedObjectID?
    ) {
        self.moc = context
        self.selectedBreadObjectIDs = selectedBreadObjectIDs
        self.currentFolderObjectID = currentFolderObjectID
    }
}

extension MoveBreadModel {
    func selectedBreadNames(inWidth maxWidth: CGFloat, withAttributes attributes: [NSAttributedString.Key : Any]) -> String {
        guard let lastName = selectedBreadNames.last else {
            return "선택된 암기빵 없음"
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
        
        let trailingText = selectedBreads.count != 1 ? " 외 \(selectedBreadNames.count - 1)개" : ""
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
        let prefixLength = prefixTrimmingLength
        var trimmedText = String(text.prefix(prefixLength))
        var resultText = trimmedText + "..." + trailingText
        while resultText.size(withAttributes: attributes).width >= maxWidth,
              trimmedText.isEmpty != true {
            _ = trimmedText.popLast()
            resultText = trimmedText + "..." + trailingText
        }
        
        return resultText
    }
    
    func selectedBreadsCount() -> String {
        return "\(selectedBreadNames.count)개의 암기빵이 선택됨"
    }
    
    var folderItems: [FolderItem] {
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
