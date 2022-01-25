//
//  Array+subscript.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/25.
//

import Foundation

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
