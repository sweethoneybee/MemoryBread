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
    static let googleSignInLightNormalImage = UIImage(named: "btn_google_signin_light_normal_web")
    static let googleSignInLightPressedImage = UIImage(named: "btn_google_signin_light_pressed_web")
    
    struct UIConstants {
        static let containerViewInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let contentViewSpacing = CGFloat(5)
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
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private var userEmailLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textAlignment = .left
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private var signInButton = UIButton()
    
    private var signOutButton = RoundedButton(frame: .zero).then {
        $0.isHidden = true
        $0.setTitle(LocalizingHelper.signOut, for: .normal)
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
        domainNameLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        userEmailLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        mainContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // MARK: - Set target-action
        signInButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
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
        
        switch auth.domain {
        case .googleDrive:
            signInButton.setBackgroundImage(RemoteDriveCell.googleSignInLightNormalImage, for: .normal)
            signInButton.setBackgroundImage(RemoteDriveCell.googleSignInLightPressedImage, for: .selected)
            signInButton.setBackgroundImage(RemoteDriveCell.googleSignInLightPressedImage, for: .highlighted)
        }

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
