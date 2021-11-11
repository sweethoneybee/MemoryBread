//
//  BreadTitleView.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/09.
//

import UIKit
import SnapKit

final class ScrollableSupplemantaryView: UICollectionReusableView {
    static let reuseIdentifier = "scrollable-supplemantary-view"
    static let font = UIFont.boldSystemFont(ofSize: 22)
    let label = UILabel()

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    func configure() {
        addSubview(label)
        label.font = Self.font
        label.numberOfLines = 0
        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
    }
}
