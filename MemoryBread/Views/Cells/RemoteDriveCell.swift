//
//  RemoteDriveCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/14.
//

import UIKit
import SnapKit

protocol RemoteDriveCellDelegate: AnyObject {
    func signOutButtonTapped(_ cell: RemoteDriveCell)
}

final class RemoteDriveCell: UITableViewCell {
    struct UIConstants {
        static let containerViewInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let contentViewSpacing = CGFloat(5)
        static let buttonInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    static let reuseIdentifier = "remote-drive-cell"
    
    weak var delegate: RemoteDriveCellDelegate?
    private var mainContainerView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fill
        $0.directionalLayoutMargins = UIConstants.containerViewInsets
        $0.spacing = UIConstants.contentViewSpacing
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    private var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
    }
    
    private var titleContainerView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .fill
    }
    
    private var domainNameLabel = UILabel().then {
        $0.font = .preferredFont(forTextStyle: .title3)
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private var userEmailLabel = UILabel().then {
        $0.font = .preferredFont(forTextStyle: .caption1)
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private var signOutButton = UIButton().then {
        $0.tintColor = .white
        $0.backgroundColor = .systemPink
        $0.layer.cornerRadius = 5
        $0.isHidden = true
        $0.contentEdgeInsets = UIConstants.buttonInsets
        $0.setTitle(LocalizingHelper.signOut, for: .normal)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(mainContainerView)

        mainContainerView.addArrangedSubview(iconImageView)
        mainContainerView.addArrangedSubview(titleContainerView)
        mainContainerView.addArrangedSubview(signOutButton)
        
        titleContainerView.addArrangedSubview(domainNameLabel)
        titleContainerView.addArrangedSubview(userEmailLabel)
        
        // MARK: - layouts
        domainNameLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        userEmailLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        mainContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // MARK: - Set target-action
        signOutButton.addTarget(self, action: #selector(signOutButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented RemoteDriveCell")
    }
}

extension RemoteDriveCell {
    func configure(using auth: DriveAuthInfo) {
        iconImageView.image = auth.domain.image
        domainNameLabel.text = auth.domain.name
        userEmailLabel.text = auth.userEmail
        
        signOutButton.isHidden = !auth.isSignIn
    }
    
    @objc
    func signOutButtonTapped() {
        delegate?.signOutButtonTapped(self)
    }
}
