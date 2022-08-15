//
//  NewLineMigrationV2toV3.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/08/07.
//

import Foundation
import CoreData

class NewLineMigrationV2toV3: NSEntityMigrationPolicy {

//    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
//        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
//
//        let srcContent = sInstance.value(forKey: "content") as! String
//        let srcSeparatedContentCount = (sInstance.value(forKey: "separatedContent") as! [String]).count
//        let srcFilterIndexes = sInstance.value(forKey: "filterIndexes") as! [[Int]]
//
//        var splittedContentWithNewLine: [String] = []
//        splitWithChar(&splittedContentWithNewLine, for: srcContent, using: "\n")
//
//        let newLineCounter = countNewLine(of: splittedContentWithNewLine, atLength: srcSeparatedContentCount)
//        let updatedFilterIndexes = srcFilterIndexes.map { row in
//            row.map { indexOfItem in
//                indexOfItem + newLineCounter[indexOfItem]
//            }
//        }
//
//        let destResults = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance])
//        if let destinationBread = destResults.last {
//            destinationBread.setValue(splittedContentWithNewLine, forKey: "separatedContent")
//            destinationBread.setValue(updatedFilterIndexes, forKey: "filterIndexes")
//            manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationBread, for: mapping)
//        }
//    }

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
//        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        let description = NSEntityDescription.entity(forEntityName: "Bread", in: manager.destinationContext)
        let newBread = Bread(entity: description!, insertInto: manager.destinationContext)

        func traversePropertyMappings(block: (NSPropertyMapping, String) -> Void) throws {
            if let attributeMappings = mapping.attributeMappings {
                for propertyMapping in attributeMappings {
                    if let destinationName = propertyMapping.name {
                        block(propertyMapping, destinationName)
                    } else {
                        let message = "Attribute destination not configured properly"
                        let userInfo = [NSLocalizedFailureReasonErrorKey: message]
                        throw NSError(domain: "NewLineMigration", code: 0, userInfo: userInfo)
                    }
                }
            } else {
                let message = "No Attribute Mappings found!"
                let userInfo = [NSLocalizedFailureReasonErrorKey: message]
                throw NSError(domain: "NewLineMigration", code: 0, userInfo: userInfo)
            }
        }

        try traversePropertyMappings { propertyMapping, destinationName in
            guard let valueExpression = propertyMapping.valueExpression else { return }

            let context: NSMutableDictionary = ["source": sInstance]
            guard let destinationValue = valueExpression.expressionValue(with: sInstance, context: context) else { return }

            newBread.setValue(destinationValue, forKey: destinationName)
        }

        let srcContent = sInstance.value(forKey: "content") as! String
        let srcSeparatedContentCount = (sInstance.value(forKey: "separatedContent") as! [String]).count
        let srcFilterIndexes = sInstance.value(forKey: "filterIndexes") as! [[Int]]

        var splittedContentWithNewLine: [String] = []
        splitWithChar(&splittedContentWithNewLine, for: srcContent, using: "\n")

        let newLineCounter = countNewLine(of: splittedContentWithNewLine, atLength: srcSeparatedContentCount)
        let updatedFilterIndexes = srcFilterIndexes.map { row in
            row.map { indexOfItem in
                indexOfItem + newLineCounter[indexOfItem]
            }
        }

        print("바뀜=\(splittedContentWithNewLine)")
        newBread.setValue(splittedContentWithNewLine, forKey: "separatedContent")
        newBread.setValue(updatedFilterIndexes, forKey: "filterIndexes")
        manager.associate(sourceInstance: sInstance, withDestinationInstance: newBread, for: mapping)
    }
    // FUNCTION($entityPolicy, "separatedContentWithNewLineFromContent:", $source.content)
    // FUNCTION($entityPolicy, "updatedFilterIndexesWithNewLineFromContent:SeparatedContent:filterIndexes:", $source.content, $source.separatedContent, $source.filterIndexes)
    // FIXME: 리턴한 값이 마이그레이션되지 못하고 있음. Transformable과 연관이 있을 듯.
    @objc
    func separatedContentWithNewLine(fromContent: String) -> [String] {
        var splittedContentWithNewLine: [String] = []
        splitWithChar(&splittedContentWithNewLine, for: fromContent, using: "\n")
        return splittedContentWithNewLine
    }
    
    // FIXME: 호출 시도 중 에러 발생
    @objc
    func updatedFilterIndexesWithNewLineFrom(
        content: String,
        separatedContent: [String],
        filterIndexes: [[Int]]
    ) -> [[Int]] {
        var splittedContentWithNewLine: [String] = []
        splitWithChar(&splittedContentWithNewLine, for: content, using: "\n")
        
        let newLineCounter = countNewLine(of: splittedContentWithNewLine, atLength: separatedContent.count)
        return filterIndexes.map { row in
            row.map { indexOfItem in
                indexOfItem + newLineCounter[indexOfItem]
            }
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
