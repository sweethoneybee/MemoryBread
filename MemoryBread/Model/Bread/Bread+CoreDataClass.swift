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
        title: String? = nil,
        content: String? = nil,
        separatedContent: [String]? = nil,
        filterIndex: [[Int]]? = nil,
        context: NSManagedObjectContext = AppDelegate.viewContext
    ) {
        self.init(context: context)
        self.touch = touch
        self.id = UUID()
        self.directoryName = directoryName
        self.title = title
        self.content = content
        self.separatedContent = separatedContent
        self.filterIndex = filterIndex
    }
}
