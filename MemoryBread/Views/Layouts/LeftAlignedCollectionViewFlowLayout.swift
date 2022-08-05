//
//  LeftAlignedCollectionViewFlowLayout.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/08/05.
//

import UIKit

final class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    // refer to
    // https://medium.com/@balzsvincze/left-aligned-uicollectionview-layout-1ff9a56562d0
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var newAttributesArray = [UICollectionViewLayoutAttributes]()
        let superAttributesArray = super.layoutAttributesForElements(in: rect)!
        for (index, attributes) in superAttributesArray.enumerated() {
            if index == 0 || superAttributesArray[index - 1].frame.origin.y != attributes.frame.origin.y {
                attributes.frame.origin.x = sectionInset.left
            } else {
                let previousAttributes = superAttributesArray[index - 1]
                let previousFrameRight = previousAttributes.frame.origin.x + previousAttributes.frame.width
                attributes.frame.origin.x = previousFrameRight + minimumInteritemSpacing
            }
            newAttributesArray.append(attributes)
        }
        return newAttributesArray
    }
}
