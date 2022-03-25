//
//  TextCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/24.
//

import UIKit
import SnapKit
import Then

final class WordCell: UICollectionViewCell {
    static var labelFont = UIFont.systemFont(ofSize: 18, weight: .regular)
    
    let label = UILabel().then {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = WordCell.labelFont
        $0.textColor = .label
        $0.numberOfLines = 0
    }
    
    let overlayView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension WordCell {
    private func configure() {
        contentView.addSubview(label)
        contentView.addSubview(overlayView)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(label)
        }
    }
    
    func configure(using item: WordPainter.Item, isEditing: Bool) {
        if isEditing {
            label.text = item.word
            overlayView.backgroundColor = item.filterColor?.withAlphaComponent(0.5) ?? .clear
            return
        }
        
        label.text = item.word
        if item.isFiltered {
            overlayView.backgroundColor = item.isPeeking ? (item.filterColor?.withAlphaComponent(0.5)) : (item.filterColor)
        } else {
            overlayView.backgroundColor = .clear
        }
    }
}
