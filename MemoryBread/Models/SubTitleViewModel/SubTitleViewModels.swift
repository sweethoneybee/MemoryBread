//
//  SubTitleViewModels.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/04/20.
//

import Foundation

protocol SubTitleViewModel {
    func makeSubTitleContent(using: [String], inWidth: CGFloat, titleAttributes: [NSAttributedString.Key: Any]) -> SubTitleViewContent
}

final class MoveBreadViewModel: SubTitleViewModel {
    func makeSubTitleContent(
        using content: [String],
        inWidth maxWidth: CGFloat,
        titleAttributes: [NSAttributedString.Key: Any]
    ) -> SubTitleViewContent {
        return SubTitleViewContent(
            text: title(for: content, inWidth: maxWidth, withAttributes: titleAttributes),
            secondaryText: breadsCount(of: content)
        )
    }
    
    private func title(
        for breadNames: [String],
        inWidth maxWidth: CGFloat,
        withAttributes attributes: [NSAttributedString.Key : Any]
    ) -> String {
        guard let lastName = breadNames.last else {
            return LocalizingHelper.noSelectedMemoryBread
        }
        
        let connectedNames = breadNames.joined(separator: ", ")
        if ceil(connectedNames.size(withAttributes: attributes).width) <= maxWidth {
            return connectedNames
        }
        
        let trailingText = breadNames.count != 1 ? " " + String(format: LocalizingHelper.andTheNumberOfBreads, breadNames.count - 1) : ""
        let omittedNames = lastName + trailingText
        if ceil(omittedNames.size(withAttributes: attributes).width) <= maxWidth {
            return omittedNames
        }
        
        let trimmedNames = iterateTrimmingSuffix(
            lastName,
            trailingBy: trailingText,
            inWidth: maxWidth,
            withAttributes: attributes
        )
        return trimmedNames
    }
    
    private func iterateTrimmingSuffix(
        _ text: String,
        trailingBy trailingText: String,
        inWidth maxWidth: CGFloat,
        withAttributes attributes: [NSAttributedString.Key : Any]
    ) -> String {
        var trimmedText = text
        var resultText = trimmedText + "..." + trailingText
        while ceil(resultText.size(withAttributes: attributes).width) > maxWidth,
              trimmedText.isEmpty != true {
            _ = trimmedText.popLast()
            resultText = trimmedText + "..." + trailingText
        }
        
        return resultText
    }
    
    private func breadsCount(of breadNames: [String]) -> String {
        return String(format: LocalizingHelper.selectedTheNumberOfMemoryBreads, breadNames.count)
    }
}
