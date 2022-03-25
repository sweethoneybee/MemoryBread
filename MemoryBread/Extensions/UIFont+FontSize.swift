//
//  UIFont+FontSize.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/26.
//

import UIKit

extension UIFont {
    func makeFontSize() -> FontSizeCalculator.FontSize {
        typealias FontSize = FontSizeCalculator.FontSize
        switch pointSize {
        case FontSize.superSmall.fontSize: return .superSmall
        case FontSize.verySmall.fontSize: return .verySmall
        case FontSize.small.fontSize: return .small
        case FontSize.medium.fontSize: return .medium
        case FontSize.big.fontSize: return .big
        case FontSize.veryBig.fontSize: return .veryBig
        case FontSize.superBig.fontSize: return .superBig
        default: return .medium
        }
    }
}
