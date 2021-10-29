//
//  UICollectionView+Selection.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit

extension UICollectionView {
    func selectAll(_ selectedImtes: [IndexPath]?, animated: Bool) {
        guard let selectedImtes = selectedImtes else { return }
        for indexPath in selectedImtes {
            selectItem(at: indexPath, animated: animated, scrollPosition: [])
        }
    }
    
    func deselectAll(animated: Bool) {
        guard let selectedItems = indexPathsForSelectedItems else { return }
        for indexPath in selectedItems {
            deselectItem(at: indexPath, animated: animated)
        }
    }
}
