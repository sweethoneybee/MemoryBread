//
//  RoundedButton.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/14.
//

import UIKit

final class RoundedButton: UIButton {
    struct UIConstants {
        static let buttonInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        static let cornerRadius: CGFloat = 5
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
}

extension RoundedButton {
    private func setup() {
        tintColor = .white
        backgroundColor = .systemPink
        layer.cornerRadius = UIConstants.cornerRadius
        contentEdgeInsets = UIConstants.buttonInsets
        titleLabel?.font = .preferredFont(forTextStyle: .title3)
        adjustsImageWhenHighlighted = true
        
        setTitleColor(titleColor(for: .normal)?.withAlphaComponent(0.3), for: .highlighted)
    }
}
