//
//  HorizontalToolbar.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/28.
//

import UIKit
import SnapKit

final class HorizontalToolBar: UIView {
    struct UIConstants {
        static let groupHeight: CGFloat = 50
        static let inset: CGFloat = 5
    }
    
    var collectionView: UICollectionView!
    var delegate: UICollectionViewDelegate? {
        didSet {
            collectionView.delegate = delegate
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: createLayout())
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = false
        addSubview(collectionView)
        configureLayouts()
        
        backgroundColor = .horizontalToolbar
        collectionView.backgroundColor = .horizontalToolbar
    }
}

// MARK: - Compositional Layout
extension HorizontalToolBar {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: UIConstants.inset,
                                                     leading: UIConstants.inset,
                                                     bottom: UIConstants.inset,
                                                     trailing: UIConstants.inset)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(UIConstants.groupHeight),
                                               heightDimension: .absolute(UIConstants.groupHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func configureLayouts() {
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(UIConstants.groupHeight)
        }
    }
}

// MARK: - Configure
extension HorizontalToolBar {
    
}
