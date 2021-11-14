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
    let label = UILabel().then {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .systemFont(ofSize: 18, weight: .regular)
        $0.textColor = .label
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
    func configure() {
        contentView.addSubview(label)
        contentView.addSubview(overlayView)
        
        label.snp.makeConstraints { make in
            let inset = CGFloat(1)
            make.leading.top.equalToSuperview().offset(inset)
            make.trailing.bottom.equalToSuperview().offset(-inset)
        }
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(label)
        }
    }
}
