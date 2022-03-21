//
//  FolderNameBlackList.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/22.
//

import Foundation

final class FolderNameBlackList {
    private init() {}

    private enum Language {
        case Korean(Array<String>)
        case English(Array<String>)
        
        var words: Array<String> {
            switch self {
            case .Korean(let w): return w
            case .English(let w): return w
            }
        }
    }
    
    private let blackList = [
        Language.Korean(["모든 암기빵" ,"암기빵", "휴지통"]),
        Language.English(["All Memory Breads", "Memory Breads", "Trash"])
    ]

    static let standard = FolderNameBlackList()

    func isInBlackList(_ name: String) -> Bool {
        for language in blackList {
            for blackWord in language.words {
                if name == blackWord {
                    return true
                }
            }
        }
        return false
    }
}
