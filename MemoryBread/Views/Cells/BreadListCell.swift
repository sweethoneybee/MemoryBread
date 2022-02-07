//
//  BreadListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
// 'ImplementingModernCollectionViews' sample code from Apple
//

import UIKit
import SnapKit

final class BreadListCell: UITableViewCell {
    static let reuseIdentifier = "bread-list-cell-reuseidentifier"
    
    private let titleAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
    private let dateAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)]
    private let bodyAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .light)]
}

extension BreadListCell {
    func configure(using bread: Bread) {
        var content = defaultContentConfiguration()
        let titleAttributedString = NSAttributedString(string: bread.title ?? "", attributes: titleAttribute)
        content.attributedText = titleAttributedString
        content.textProperties.numberOfLines = 1
        
        let dateString = DateHelper.default.string(from: bread.touch ?? Date())
        let secondaryAttributedString = NSMutableAttributedString(string: dateString + " ", attributes: dateAttribute)
        secondaryAttributedString.append(NSAttributedString(string: String((bread.content ?? "").prefix(200)), attributes: bodyAttribute))
        
        content.secondaryAttributedText = secondaryAttributedString
        content.secondaryTextProperties.numberOfLines = 1
        
        self.contentConfiguration = content
    }
}
