//
//  NewLineMigrationV2toV3.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/08/07.
//

import Foundation
import CoreData

class NewLineMigrationV2toV3: NSEntityMigrationPolicy {

    // FUNCTION($entityPolicy, "seperatedContentWithNewLineFromContent:", $source.content)
    // FUNCTION($entityPolicy, "updatedFilterIndexesWithNewLineFromContent:SeperatedContent:filterIndexes:", $source.content, $source.seperatedContent, $source.filterIndexes)
    @objc
    func seperatedContentWithNewLine(fromContent: String) -> [String] {
        var splittedContentWithNewLine: [String] = []
        splitWithChar(&splittedContentWithNewLine, for: fromContent, using: "\n")
        return splittedContentWithNewLine
    }
    
    @objc
    func updatedFilterIndexesWithNewLineFrom(
        content: String,
        seperatedContent: [String],
        filterIndexes: [[Int]]
    ) -> [[Int]] {
        var splittedContentWithNewLine: [String] = []
        splitWithChar(&splittedContentWithNewLine, for: content, using: "\n")
        
        let newLineCounter = countNewLine(of: splittedContentWithNewLine, atLength: seperatedContent.count)
        return filterIndexes.map { row in
            row.map { indexOfItem in
                indexOfItem + newLineCounter[indexOfItem]
            }
        }
    }
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        let srcContent = sInstance.value(forKey: "content") as! String
        let srcSeperatedContentCount = (sInstance.value(forKey: "seperatedContent") as! [String]).count
        let srcFilterIndexes = sInstance.value(forKey: "filterIndexes") as! [[Int]]

        var splittedContentWithNewLine: [String] = []
        splitWithChar(&splittedContentWithNewLine, for: srcContent, using: "\n")

        let newLineCounter = countNewLine(of: splittedContentWithNewLine, atLength: srcSeperatedContentCount)
        let updatedFilterIndexes = srcFilterIndexes.map { row in
            row.map { indexOfItem in
                indexOfItem + newLineCounter[indexOfItem]
            }
        }

        let destResults = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance])
        if let destinationBread = destResults.last {
            destinationBread.setValue(splittedContentWithNewLine, forKey: "seperatedContent")
            destinationBread.setValue(updatedFilterIndexes, forKey: "filterIndexes")
        }
    }
    
    private func splitWithChar(_ arr: inout [String], for str: String, using char: Character) {
        guard !str.isEmpty else { return }
        var firstIndex = str.firstIndex(of: char) ?? str.endIndex
        
        if firstIndex != str.startIndex {
            arr.append(String(str[..<firstIndex]))
            splitWithChar(&arr, for: String(str[firstIndex...]), using: char)
            return
        }
        
        arr.append(String(str[firstIndex]))
        firstIndex = str.index(after: firstIndex)
        splitWithChar(&arr, for: String(str[firstIndex...]), using: char)
    }
    
    private func countNewLine(of splittedContentWithNewLine: [String], atLength length: Int) -> [Int] {
        var newLineCounter = Array(repeating: 0, count: length)
        var count = 0
        var index = 0
        splittedContentWithNewLine.forEach {
            if $0 == "\n" {
                count += 1
                return
            }
            newLineCounter[index] = count
            index += 1
        }
        
        return newLineCounter
    }
    
}
