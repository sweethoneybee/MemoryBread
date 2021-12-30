//
//  ExcelReader.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/12.
//

import Foundation
import CoreXLSX

final class ExcelReader {
    static let maxRowsCount = 500
    static func readXLSXFile(
        at fileURL: URL,
        completionHandler: @escaping (Result<[[String]], ExcelReaderError>)->()
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let xlsxFile = XLSXFile(filepath: fileURL.path) else {
                DispatchQueue.main.async {
                    completionHandler(.failure(ExcelReaderError.failToReadXLSXFile))
                }
                return
            }
            
            var rows: [[String]] = []
            do {
                for wbk in try xlsxFile.parseWorkbooks() {
                    for (_, path) in try xlsxFile.parseWorksheetPathsAndNames(workbook: wbk) {
                        let worksheet = try xlsxFile.parseWorksheet(at: path)
                        if let sharedStrings = try xlsxFile.parseSharedStrings() {
                            for row in worksheet.data?.rows ?? [] {
                                let rowCStrings = row.cells.compactMap { $0.stringValue(sharedStrings) }
                                if rowCStrings.count == 0 {
                                    continue
                                }
                                rows.append(Array(rowCStrings.prefix(2)))
                            }
                        }
                    }
                }
            } catch  {
                DispatchQueue.main.async {
                    completionHandler(.failure(ExcelReaderError.xlsxFileIsNotVaild))
                }
                return
            }
            
            if rows.count == 0 {
                DispatchQueue.main.async {
                    completionHandler(.failure(.xlsxFileIsEmpty))
                }
                return
            }
            
            if rows.count > ExcelReader.maxRowsCount {
                DispatchQueue.main.async {
                    completionHandler(.failure(.rowsAreTooMany(ExcelReader.maxRowsCount)))
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(.success(rows))
            }
        }
    }
}
