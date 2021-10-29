//
//  FixedHorizontalToolbar.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit

final class FixedHorizontalScrollToolBar: UIView {
    private var scrollView: UIScrollView
    private var contentView: UIView
    private var stackView: UIStackView

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    var _itemSpacing: CGFloat = 10
    var itemSpacing: CGFloat {
        get { _itemSpacing }
        set { stackView.spacing = newValue }
    }

    override init(frame: CGRect) {
        scrollView = UIScrollView().then {
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false
        }

        contentView = UIView()

        stackView = UIStackView().then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .equalSpacing
        }

        super.init(frame: frame)
        configure()
        configureLayouts()
    }

    convenience init() {
        self.init(frame: .zero)
    }
}

// MARK: - Configure Views
extension FixedHorizontalScrollToolBar {
    private func configure() {
        backgroundColor = .brown
        stackView.spacing = itemSpacing

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
    }

    private func configureLayouts() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            let inset = CGFloat(5)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
        }
    }
}

extension FixedHorizontalScrollToolBar {
    func appendSubview(_ view: UIView, size: CGSize = CGSize(width: 50, height: 50)) {
        stackView.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
    }

    func appendSubviews(_ views: [UIView], size: CGSize = CGSize(width: 50, height: 50)) {
        views.forEach {
            stackView.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
            }
        }
    }
}
