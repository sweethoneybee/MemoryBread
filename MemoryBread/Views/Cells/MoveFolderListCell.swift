//
//  MoveFolderListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/12.
//

import UIKit
import CoreData

final class MoveFolderListCell: UITableViewCell {
    static let cellReuseIdentifier = "move-folder-list-cell-reuse-identifier"
    
    struct Item: Hashable {
        let name: String
        let disabled: Bool
        let objectID: NSManagedObjectID?
    }
    
    var item: Item?
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        let content: UIContentConfiguration
        if item?.objectID == nil {
            content = makeCreateFolderCellContent()
        } else {
            content = makeFolderCellContent()
        }
        self.contentConfiguration = content
    }
    
    private func makeFolderCellContent() -> UIContentConfiguration {
        var content = defaultContentConfiguration()

        content.text = item?.name
        content.image = UIImage(systemName: "folder")
        
        if case true? = item?.disabled {
            content.textProperties.color = .systemGray
            content.imageProperties.tintColor = .systemGray
        }
        
        return content
    }
    
    private func makeCreateFolderCellContent() -> UIContentConfiguration {
        var content = defaultContentConfiguration()
        content.text = item?.name
        content.textProperties.color = .systemPink
        return content
    }
}

