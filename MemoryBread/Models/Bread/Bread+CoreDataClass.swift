//
//  Bread+CoreDataClass.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//
//

import Foundation
import CoreData
import UIKit

@objc(Bread)
public class Bread: NSManagedObject {
    convenience init(
        touch: Date?,
        directoryName: String?,
        title: String?,
        content: String?,
        separatedContent: [String]?,
        filterIndexes: [[Int]]?,
        context: NSManagedObjectContext = AppDelegate.viewContext
    ) {
        self.init(context: context)
        self.createdTime = Date()
        self.id = UUID()
        self.touch = touch
        self.directoryName = directoryName
        self.title = title
        self.content = content
        self.separatedContent = separatedContent
        self.filterIndexes = filterIndexes
    }
}
