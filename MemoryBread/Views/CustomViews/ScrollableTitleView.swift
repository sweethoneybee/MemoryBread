//
//  FixedHorizontalToolbar.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit
import Then

final class ScrollableTitleView: UIView {
    static let intrinsicHeight: CGFloat = 50
    
    private var scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
    }
    
    private var contentView = UIView()
    
    private var stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    private var titleLabel = UILabel().then {
        $0.font = .preferredFont(forTextStyle: .title2)
        $0.numberOfLines = 1
    }
    
    var _text = ""
    var text: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        configureLayouts()
    }

    convenience init() {
        self.init(frame: .zero)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: Self.intrinsicHeight)
    }
}

// MARK: - Configure Views
extension ScrollableTitleView {
    private func configure() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
    }

    private func configureLayouts() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}
