//
//  String+size.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/12.
//

import UIKit

// from https://stackoverflow.com/questions/30450434/figure-out-size-of-uilabel-based-on-string-in-swift
extension String {
    func height(withConstraintWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintBox = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintBox, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
}
