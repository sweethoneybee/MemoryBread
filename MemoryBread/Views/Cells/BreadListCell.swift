//
//  BreadListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
// 'ImplementingModernCollectionViews' sample code from Apple
//

import UIKit
import SnapKit

class BreadListCell: UICollectionViewListCell {
    static let reuseIdentifier = "bread-list-cell-reuseidentifier"
    
    let titleLabel = UILabel()
    let dateLabel = UILabel()
    let bodyLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension BreadListCell {
    func configure() {
        titleLabel.adjustsFontForContentSizeCategory = true
        dateLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.adjustsFontForContentSizeCategory = true
        
        titleLabel.numberOfLines = 1
        bodyLabel.numberOfLines = 1
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .ultraLight)
        bodyLabel.font = UIFont.systemFont(ofSize: 12, weight: .light)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(bodyLabel)
        
        let leadingInset = CGFloat(20)
        let topInset = CGFloat(10)
        let topOffset = CGFloat(5)
        titleLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.trailing.equalToSuperview().inset(topInset)
            make.leading.equalToSuperview().inset(leadingInset)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(topOffset)
            make.leading.equalToSuperview().inset(leadingInset)
            make.bottom.equalToSuperview().inset(topInset)
            make.width.equalTo(70)
        }
        
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(topOffset)
            make.leading.equalTo(dateLabel.snp.trailing)
            make.trailing.equalToSuperview().inset(topInset)
            make.bottom.equalToSuperview().inset(topInset)
        }
    }
}
