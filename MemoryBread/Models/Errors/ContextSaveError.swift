//
//  ContextSaveError.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/22.
//

import Foundation

enum ContextSaveError: Error {
    case folderNameIsDuplicated
    case folderNameIsInBlackList
    case unknown(NSError)
}
