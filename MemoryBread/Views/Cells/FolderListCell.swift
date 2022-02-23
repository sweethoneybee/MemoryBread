//
//  FolderListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/29.
//

import UIKit

final class FolderListCell: UITableViewCell {
    
    struct Item {
        var title: String
        var pinnedAtTop: Bool
        var pinnedAtBottom: Bool
        var count: Int64
        var imageName: String {
            if pinnedAtBottom {
                return "trash"
            }
            return "folder"
        }
        
        init(folderObject: Folder) {
            self.title = folderObject.name ?? ""
            self.pinnedAtTop = folderObject.pinnedAtTop
            self.pinnedAtBottom = folderObject.pinnedAtBottom
            self.count = folderObject.breadsCount
        }
    }
    
    private var item: Item?
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var content = UIListContentConfiguration.valueCell().updated(for: state)
        
        content.image = UIImage(systemName: item?.imageName ?? "")?.withTintColor(.systemPink)
        content.text = item?.title
        content.secondaryText = "\(item?.count ?? 0)  >"

        if state.isEditing
            && (item?.pinnedAtTop == true || item?.pinnedAtBottom == true) {
            content.imageProperties.tintColor = .systemGray
            content.textProperties.color = .systemGray
        }
        
        self.contentConfiguration = content
    }
    
    func inject(_ item: Item) {
        self.item = item
    }
}
