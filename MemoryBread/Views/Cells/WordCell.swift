//
//  TextCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/24.
//

import UIKit
import SnapKit
import Then

class WordCell: UICollectionViewCell {
    let label = UILabel().then {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .body)
        $0.textColor = .black
    }
    
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
        layer.cornerRadius = 10
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            let inset = CGFloat(2)
            make.leading.top.equalToSuperview().offset(inset)
            make.trailing.bottom.equalToSuperview().offset(-inset)
        }
    }
    
    func didSelected(_ isSelected: Bool) {
        backgroundColor = isSelected ? .blue : .white
        label.textColor = isSelected ? .white : .black
    }
}
