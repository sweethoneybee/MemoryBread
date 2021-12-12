//
//  ExcelReader.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/12.
//

import Foundation
import CoreXLSX

final class ExcelReader {
    static func readWorkSheet(from data: Data) -> [[String]]? {
        var rows: [[String]] = []
        do {
            let xlsxFile = try XLSXFile(data: data)
            for wbk in try xlsxFile.parseWorkbooks() {
                for (_, path) in try xlsxFile.parseWorksheetPathsAndNames(workbook: wbk) {
                    let worksheet = try xlsxFile.parseWorksheet(at: path)
                    if let sharedStrings = try xlsxFile.parseSharedStrings() {
                        for row in worksheet.data?.rows ?? [] {
                            if row.cells.count <= 2 {
                                let rowCStrings = row.cells.compactMap { $0.stringValue(sharedStrings) }
                                rows.append(rowCStrings)
                            }
                        }
                    }
                }
            }
        } catch {
            return nil
        }
        return rows
    }
}
