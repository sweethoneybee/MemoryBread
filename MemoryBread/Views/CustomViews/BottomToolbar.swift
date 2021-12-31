//
//  BottomToolbar.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/31.
//

import UIKit

final class BottomToolbar: UIView {

    struct UIConstants {
        static let containerViewInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let spacing = CGFloat(5)
    }
    
    // MARK: - Views
    
    private let containerView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .top
        $0.distribution = .fill
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = UIConstants.containerViewInsets
        $0.spacing = UIConstants.spacing
    }
    
    private let spaceFillView = UIView().then {
        $0.backgroundColor = .clear
        $0.setContentHuggingPriority(.init(1), for: .horizontal)
    }
    
    // MARK: - Life Cycle
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
}

extension BottomToolbar {
    private func setup() {
        backgroundColor = .systemGray5.withAlphaComponent(0.99)
        
        addSubview(containerView)
        containerView.addArrangedSubview(spaceFillView)
        
        // MARK: - layouts
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Interface
extension BottomToolbar {
    enum Side {
        case left, right
    }
    
    /// `addedView` should have its intrinsic size
    func addArrangedSubview(_ addedView: UIView, to side: Side) {
        switch side {
        case .left:
            containerView.insertArrangedSubview(addedView, at: 0)
        case .right:
            containerView.addArrangedSubview(addedView)
        }
    }
}
