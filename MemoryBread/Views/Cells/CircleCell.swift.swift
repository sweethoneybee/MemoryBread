//
//  CircleCell.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit

final class CircleCell: UICollectionViewCell {

    static let borderWidth: CGFloat = 2
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = bounds.width / 2
        layer.borderColor = UIColor.white.cgColor
        setBorderWidth(isSelected: isSelected)
    }
    
    override var isSelected: Bool {
        didSet {
            setBorderWidth(isSelected: isSelected)
        }
    }
    
    private func setBorderWidth(isSelected: Bool) {
        layer.borderWidth = isSelected ? CircleCell.borderWidth : 0
    }
}
