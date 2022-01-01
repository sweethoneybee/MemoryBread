//
//  ExcelReaderError.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/30.
//

import Foundation

enum ExcelReaderError: Error {
    case failToReadXLSXFile
    case xlsxFileIsNotVaild
    case xlsxFileIsEmpty
    case rowsAreTooMany(Int)
}

extension ExcelReaderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failToReadXLSXFile:
            return LocalizingHelper.failToReadXLSXFile
        case .xlsxFileIsNotVaild:
            return LocalizingHelper.xlsxFileIsNotVaild
        case .xlsxFileIsEmpty:
            return LocalizingHelper.xlsxFileIsEmpty
        case .rowsAreTooMany(let maxCount):
            return String(format: LocalizingHelper.rowsAreTooMany, maxCount)
        }
    }
}
