//
//  CircleCell.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit

final class CircleCell: UICollectionViewCell {

    static let borderWidth: CGFloat = 5
    
    private let countLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.adjustsFontSizeToFitWidth = true
        $0.textAlignment = .center
        $0.textColor = .white
    }
    
    var text: String = "" {
        didSet {
            countLabel.text = self.text.count < 3 ? self.text : "99+"
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = bounds.width / 2
        layer.borderColor = UIColor.circleCellLayer.cgColor
        setBorderWidth(isSelected: isSelected)
        
        contentView.addSubview(countLabel)
        
        countLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview().dividedBy(2)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            setBorderWidth(isSelected: isSelected)
        }
    }
    
    private func setBorderWidth(isSelected: Bool) {
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
            self?.layer.borderWidth = isSelected ? CircleCell.borderWidth : 0
        })
    }
}
