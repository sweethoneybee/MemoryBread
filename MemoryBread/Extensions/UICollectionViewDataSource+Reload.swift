//
//  UICollectionViewDataSource+Reload.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/23.
//

import UIKit

extension UICollectionViewDiffableDataSource {
    func reconfigure(_ identifiers: [ItemIdentifierType], animatingDifferences: Bool = false) {
        var snapshot = snapshot()
        if #available(iOS 15.0, *) {
            snapshot.reconfigureItems(identifiers)
            apply(snapshot, animatingDifferences: animatingDifferences)
        } else {
            snapshot.reloadItems(identifiers)
            apply(snapshot, animatingDifferences: false)
        }
    }
}
