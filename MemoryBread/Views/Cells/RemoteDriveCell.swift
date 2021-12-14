//
//  RemoteDriveCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/14.
//

import UIKit
import SnapKit

protocol RemoteDriveCellDelegate: AnyObject {
    func signInButtonTapped(_ cell: RemoteDriveCell)
    func signOutButtonTapped(_ cell: RemoteDriveCell)
}

final class RemoteDriveCell: UITableViewCell {
    struct UIConstants {
        static let contentViewInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        static let contentViewSpacing = CGFloat(5)
        static let buttonInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    static let reuseIdentifier = "remote-drive-cell"
    
    weak var delegate: RemoteDriveCellDelegate?
    private var mainContainerView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fill
        $0.layoutMargins = UIConstants.contentViewInsets
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
    
    private static func makeSignButton() -> UIButton {
        return UIButton().then {
            $0.tintColor = .white
            $0.backgroundColor = .systemPink
            $0.layer.cornerRadius = 5
            $0.isHidden = true
            $0.contentEdgeInsets = UIConstants.buttonInsets
        }
    }
    
    private var signInButton = RemoteDriveCell.makeSignButton().then {
        $0.setTitle(LocalizingHelper.signIn, for: .normal)
        $0.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
    }

    private var signOutButton = RemoteDriveCell.makeSignButton().then {
        $0.setTitle(LocalizingHelper.signOut, for: .normal)
        $0.addTarget(self, action: #selector(signOutButtonTapped), for: .touchUpInside)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(mainContainerView)

        mainContainerView.addArrangedSubview(iconImageView)
        mainContainerView.addArrangedSubview(titleContainerView)
        mainContainerView.addArrangedSubview(signInButton)
        mainContainerView.addArrangedSubview(signOutButton)
        
        titleContainerView.addArrangedSubview(domainNameLabel)
        titleContainerView.addArrangedSubview(userEmailLabel)
        
        // MARK: - layouts
        titleContainerView.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        domainNameLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        userEmailLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        mainContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        
        signInButton.isHidden = auth.isSignIn
        signOutButton.isHidden = !auth.isSignIn
    }
    
    @objc
    func signInButtonTapped() {
        delegate?.signInButtonTapped(self)
    }
    
    @objc
    func signOutButtonTapped() {
        delegate?.signOutButtonTapped(self)
    }
}
