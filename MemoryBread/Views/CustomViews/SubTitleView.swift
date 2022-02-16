//
//  SubTitleView.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/16.
//

import UIKit

struct SubTitleViewContent {
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
    
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    
    var content: SubTitleViewContent? {
        didSet {
            guard let content = content else {
                return
            }
            update(using: content)
        }
    }
    
    var titleFont = UIFont.preferredFont(forTextStyle: .title2) {
        didSet {
            titleLabel.font = titleFont
        }
    }
    
    var subTitleFont = UIFont.preferredFont(forTextStyle: .callout) {
        didSet {
            subTitleLabel.font = subTitleFont
        }
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

        titleLabel.font = titleFont
        subTitleLabel.font = subTitleFont
    }
    
    private func update(using content: SubTitleViewContent) {
        titleLabel.text = content.text
        subTitleLabel.text = content.secondaryText
    }
    
    func titleWidth() -> CGFloat {
        return frame.width - CGFloat(40)
    }
}
