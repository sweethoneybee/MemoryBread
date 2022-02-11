//
//  MoveFolderListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/12.
//

import UIKit

final class MoveFolderListCell: UITableViewCell {
    static let cellReuseIdentifier = "move-folder-list-cell-reuse-identifier"
    typealias Item = MoveBreadModel.FolderItem
    
    var item: Item?
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var content = defaultContentConfiguration()
        
        content.text = item?.name
        content.image = UIImage(systemName: "folder")
        
        if case true? = item?.disabled {
            content.textProperties.color = .systemGray
            content.imageProperties.tintColor = .systemGray
        }
        
        self.contentConfiguration = content
    }
}

