//
//  BreadListCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
// 'ImplementingModernCollectionViews' sample code from Apple
//

import UIKit
import SnapKit

final class BreadListCell: UITableViewCell {
    static let reuseIdentifier = "bread-list-cell-reuseidentifier"
    
    private let folderAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .light)]
    private let dateAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)]
    private let bodyAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .light)]
    
    private let mainView = UIStackView(frame: .zero).then {
        $0.axis = .vertical
        $0.distribution = .equalSpacing
        $0.alignment = .fill
        $0.spacing = 3
    }
    
    private let titleLabel = UILabel(frame: .zero).then {
        $0.font = .boldSystemFont(ofSize: 16)
        $0.numberOfLines = 1
        $0.textAlignment = .left
    }
    
    private let subTitleLabel = UILabel(frame: .zero).then {
        $0.numberOfLines = 1
        $0.textAlignment = .left
    }
    
    private let folderLine = UIStackView(frame: .zero).then {
        $0.axis = .horizontal
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    private let folderImageView = UIImageView(frame: .zero).then {
        $0.image = UIImage(systemName: "folder")
        $0.tintColor = .gray
        $0.contentMode = .scaleAspectFit
    }
    
    private let folderLabel = UILabel(frame: .zero).then {
        $0.font = .systemFont(ofSize: 12, weight: .ultraLight)
        $0.numberOfLines = 1
        $0.textAlignment = .left
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}

extension BreadListCell {
    private func setup() {
        contentView.addSubview(mainView)
        mainView.addArrangedSubview(titleLabel)
        mainView.addArrangedSubview(subTitleLabel)
        mainView.addArrangedSubview(folderLine)
        
        folderLine.addArrangedSubview(folderImageView)
        folderLine.addArrangedSubview(folderLabel)
        folderLine.isHidden = true
        
        mainView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.bottom.equalToSuperview().inset(11)
        }
    }

    func configure(using bread: Bread, showFolder: Bool = false) {
        titleLabel.text = bread.title
        
        let dateString = DateHelper.default.string(from: bread.touch)
        let secondaryAttributedString = NSMutableAttributedString(string: dateString + " ", attributes: dateAttribute)
        secondaryAttributedString.append(NSAttributedString(string: String((bread.content).prefix(200)), attributes: bodyAttribute))
        subTitleLabel.attributedText = secondaryAttributedString
        
        folderLine.isHidden = !showFolder
        if showFolder {
            folderLabel.text = bread.folder.localizedName
        }
    }
}
