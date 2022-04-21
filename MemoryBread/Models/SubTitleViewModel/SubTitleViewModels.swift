//
//  SubTitleViewModels.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/04/20.
//

import Foundation

protocol SubTitleViewModel {
    func makeSubTitleContent(
        using: [String],
        titleAttributes: [NSAttributedString.Key: Any],
        inWidth: CGFloat
    ) -> SubTitleViewContent
}

final class MoveBreadViewModel: SubTitleViewModel {
    func makeSubTitleContent(
        using content: [String],
        titleAttributes: [NSAttributedString.Key: Any],
        inWidth maxWidth: CGFloat
    ) -> SubTitleViewContent {
        return SubTitleViewContent(
            text: title(for: content, withAttributes: titleAttributes, inWidth: maxWidth),
            secondaryText: breadsCountText(of: content)
        )
    }
    
    private func title(
        for breadNames: [String],
        withAttributes attributes: [NSAttributedString.Key : Any],
        inWidth maxWidth: CGFloat
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
            withAttributes: attributes,
            inWidth: maxWidth
        )
        return trimmedNames
    }
    
    private func iterateTrimmingSuffix(
        _ text: String,
        trailingBy trailingText: String,
        withAttributes attributes: [NSAttributedString.Key : Any],
        inWidth maxWidth: CGFloat
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
    
    private func breadsCountText(of breadNames: [String]) -> String {
        return String(format: LocalizingHelper.selectedTheNumberOfMemoryBreads, breadNames.count)
    }
}

final class CopyAndMoveViewModel: SubTitleViewModel {
    private let sourceFolderName: String
    init(sourceFolderName: String) {
        self.sourceFolderName = sourceFolderName
    }
    
    func makeSubTitleContent(
        using content: [String],
        titleAttributes: [NSAttributedString.Key : Any],
        inWidth maxWidth: CGFloat
    ) -> SubTitleViewContent {
        return SubTitleViewContent(
            text: title(for: content, withAttributes: titleAttributes, inWidth: maxWidth),
            secondaryText: String(format: LocalizingHelper.copyFromFolder, sourceFolderName)
        )
    }
    
    private func title(
        for breadNames: [String],
        withAttributes attributes: [NSAttributedString.Key : Any],
        inWidth maxWidth: CGFloat
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
            withAttributes: attributes,
            inWidth: maxWidth
        )
        return trimmedNames
    }
    
    private func iterateTrimmingSuffix(
        _ text: String,
        trailingBy trailingText: String,
        withAttributes attributes: [NSAttributedString.Key : Any],
        inWidth maxWidth: CGFloat
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
}
