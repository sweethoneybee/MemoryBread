//
//  FilterColor.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/30.
//

import UIKit

enum FilterColor: Int, CaseIterable {
    case pink, blue, mint, indigo, yellow
    case orange, purple
    func color() -> UIColor {
        switch self {
        case .pink: return UIColor.systemPink
        case .blue: return UIColor.systemBlue
        case .mint: return UIColor.systemMint
        case .indigo: return UIColor.systemIndigo
        case .yellow: return UIColor.systemYellow
        case .orange: return UIColor.systemOrange
        case .purple: return UIColor.systemPurple
        }
    }
    
    static var count: Int {
        FilterColor.allCases.count
    }
    
    static func colorIndex(for color: UIColor?) -> Int? {
        guard let color = color else { return nil }
        switch color {
        case .systemPink: return FilterColor.pink.rawValue
        case .systemBlue: return FilterColor.blue.rawValue
        case .systemMint: return FilterColor.mint.rawValue
        case .systemIndigo: return FilterColor.indigo.rawValue
        case .systemYellow: return FilterColor.yellow.rawValue
        case .systemOrange: return FilterColor.orange.rawValue
        case .systemPurple: return FilterColor.purple.rawValue
        default: return nil
        }
    }
}
