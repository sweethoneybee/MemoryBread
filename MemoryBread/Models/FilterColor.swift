//
//  FilterColor.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/30.
//

import UIKit

enum FilterColor: Int, CaseIterable {
    case red, blue, yellow, brown
    func color() -> UIColor {
        switch self {
        case .red: return UIColor.red
        case .blue: return UIColor.blue
        case .yellow: return UIColor.yellow
        case .brown: return UIColor.brown
        }
    }
    
    static var count: Int {
        FilterColor.allCases.count
    }
    
    static func colorIndex(for color: UIColor?) -> Int? {
        guard let color = color else { return nil }
        switch color {
        case .red: return FilterColor.red.rawValue
        case .blue: return FilterColor.blue.rawValue
        case .yellow: return FilterColor.yellow.rawValue
        case .brown: return FilterColor.brown.rawValue
        default: return nil
        }
    }
}
