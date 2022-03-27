//
//  WordSizeCalculator.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/26.
//

import Foundation

final class WordSizeCalculator {
    func wordSize(of sliderValue: Float) -> WordSize {
        let roundedValue = lroundf(sliderValue * 100)
        
        let newFontSize: WordSize
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

enum WordSize: Int {
    case superSmall
    case verySmall
    case small
    case medium
    case big
    case veryBig
    case superBig
    
    init(rawValue: Int) {
        switch rawValue {
        case 0: self = .superSmall
        case 1: self = .verySmall
        case 2: self = .small
        case 3: self = .medium
        case 4: self = .big
        case 5: self = .veryBig
        case 6: self = .superBig
        default: self = .medium
        }
    }
    
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
