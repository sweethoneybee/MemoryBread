//
//  String+Helper.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/12.
//

import UIKit

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", comment: "")
    }
}

extension String {
    /// from https://stackoverflow.com/questions/30450434/figure-out-size-of-uilabel-based-on-string-in-swift
    /// by Kaan Dedeoglu
    func height(withConstraintWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintBox = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintBox, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
}

extension String {
    /// from https://stackoverflow.com/questions/32212220/how-to-split-a-string-into-substrings-of-equal-length
    /// by Wujo
    func components(withMaxLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length)
            .map {
                let start = self.index(startIndex, offsetBy: $0)
                let end = self.index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
                return String(self[start..<end])
            }
    }
}
