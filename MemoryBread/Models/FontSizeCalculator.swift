//
//  FontSizeCalculator.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/26.
//

import Foundation

final class FontSizeCalculator {
    enum FontSize {
        case superSmall
        case verySmall
        case small
        case medium
        case big
        case veryBig
        case superBig
        
        var sliderValue: Float {
            switch self {
            case .superSmall: return 0
            case .verySmall: return 0.166
            case .small: return 0.332
            case .medium: return 0.5
            case .big: return 0.666
            case .veryBig: return 0.832
            case .superBig: return 1
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .superSmall: return 9
            case .verySmall: return 12
            case .small: return 15
            case .medium: return 18
            case .big: return 24
            case .veryBig: return 30
            case .superBig: return 36
            }
        }
    }
    
    func fontSize(of sliderValue: Float) -> FontSize {
        let roundedValue = lroundf(sliderValue * 100)
        
        let newFontSize: FontSize
        switch roundedValue {
        case 0..<8: newFontSize = .superSmall
        case 8..<26: newFontSize = .verySmall
        case 26..<43: newFontSize = .small
        case 43..<60: newFontSize = .medium
        case 60..<79: newFontSize = .big
        case 79..<92: newFontSize = .veryBig
        case 92...100: newFontSize = .superBig
        default: newFontSize = .superBig
        }
        
        return newFontSize
    }
}
