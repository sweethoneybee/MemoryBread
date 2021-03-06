//
//  SubTitleView.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/16.
//

import UIKit

struct SubTitleContent {
    var text: String?
    var secondaryText: String?
}

final class SubTitleView: UIView {
    private static let verticalMargin = CGFloat(10)
    private static let horizontalMargin = CGFloat(20)
    
    private let mainView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    private lazy var titleLabel = UILabel().then {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = titleFont
    }
    
    private let subTitleLabel = UILabel().then {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = .preferredFont(forTextStyle: .callout)
    }
    
    var content: SubTitleContent? {
        didSet {
            guard let content = content else {
                return
            }
            update(using: content)
        }
    }
    
    var titleFont: UIFont {
        UIFont.preferredFont(forTextStyle: .title2)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override var intrinsicContentSize: CGSize {
        let width = titleLabel.frame.width + Self.horizontalMargin * 2
        let height = titleLabel.frame.height + subTitleLabel.frame.height + Self.verticalMargin * 2
        return CGSize(width: width, height: height)
    }
}

extension SubTitleView {
    private func setup() {
        backgroundColor = .systemBackground
        addSubview(mainView)
        mainView.addArrangedSubview(titleLabel)
        mainView.addArrangedSubview(subTitleLabel)
        mainView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(SubTitleView.verticalMargin)
            make.leading.trailing.equalToSuperview().inset(SubTitleView.horizontalMargin)
        }
    }
    
    private func update(using content: SubTitleContent) {
        titleLabel.text = content.text
        subTitleLabel.text = content.secondaryText
        
        titleLabel.sizeToFit()
        subTitleLabel.sizeToFit()
    }
    
    func titleWidth(inWidth width: CGFloat) -> CGFloat {
        return width - Self.horizontalMargin * 2
    }
}
