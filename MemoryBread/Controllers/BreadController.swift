//
//  BreadController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/01.
//

import UIKit

final class BreadController {
    struct WordItem: Hashable {
        let identifier = UUID()
        let word: String
        var isFiltered: Bool = false
        var isPeeking: Bool = false
        var filterColor: UIColor?
  
        init(word: String) {
            self.word = word
        }
        
        init(_ item: Self) {
            self.word = item.word
            self.isFiltered = item.isFiltered
            self.isPeeking = item.isPeeking
            self.filterColor = item.filterColor
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
}
