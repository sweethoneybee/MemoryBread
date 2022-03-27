//
//  UIFont+FontSize.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/26.
//

import UIKit

extension UIFont {
    func makeWordSize() -> WordSize {
        switch pointSize {
        case WordSize.superSmall.fontSize: return .superSmall
        case WordSize.verySmall.fontSize: return .verySmall
        case WordSize.small.fontSize: return .small
        case WordSize.medium.fontSize: return .medium
        case WordSize.big.fontSize: return .big
        case WordSize.veryBig.fontSize: return .veryBig
        case WordSize.superBig.fontSize: return .superBig
        default: return .medium
        }
    }
}
