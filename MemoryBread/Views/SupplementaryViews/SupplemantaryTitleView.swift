//
//  BreadTitleView.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/09.
//

import UIKit
import SnapKit

protocol SupplemantaryTitleViewDelegate: AnyObject {
    func didTapTitleView(_ view: UICollectionReusableView)
}

final class SupplemantaryTitleView: UICollectionReusableView {
    struct UIConstants {
        static let bottomInset: CGFloat = 10
        static let minimumHeight: CGFloat = 37 + bottomInset
    }
    
    static let reuseIdentifier = "scrollable-supplemantary-view"
    static let font = UIFont.boldSystemFont(ofSize: 22)
    
    
    weak var delegate: SupplemantaryTitleViewDelegate?
    let label = UILabel()
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
}

extension SupplemantaryTitleView {
    private func configure() {
        addSubview(label)
        label.isUserInteractionEnabled = true
        label.font = Self.font
        label.numberOfLines = 0
        label.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(BreadViewController.UIConstants.edgeInset)
            make.bottom.equalToSuperview().inset(UIConstants.bottomInset)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTitleView))
        label.addGestureRecognizer(tapGesture)
    }
                                  
    func configure(using text: String?) {
        label.text = text
    }
    
    @objc
    func didTapTitleView() {
        delegate?.didTapTitleView(self)
    }
}
