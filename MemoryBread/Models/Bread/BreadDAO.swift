//
//  BreadDAO.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//

import Foundation
import CoreData

extension Notification.Name {
    static let breadObjectsDidChange = Notification.Name("breadObjectsDidChange")
}

final class BreadDAO: NSObject {
    static let `default` = BreadDAO()
    
    private let context = AppDelegate.viewContext
    private lazy var fetchedResultController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "touch", ascending: false)]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        do {
            try controller.performFetch()
        } catch {
            fatalError("perform fetch failed")
        }
        
        controller.delegate = self
        return controller
    }()
    
    var allBreads: [Bread] {
        if let breadObjects = fetchedResultController.fetchedObjects {
            return breadObjects
        }
        return [Bread]()
    }
    
    private func Log(title: String, error: Error) {
        NSLog("\(title) failed. Error=\(error)")
    }
    
    @discardableResult
    func save() -> Bool {
        do {
            try context.save()
        } catch {
            Log(title: "save()", error: error)
            return false
        }
        return true
    }
    
    @discardableResult
    func delete(at indexPath: IndexPath) -> Bool {
        let breadObject = fetchedResultController.object(at: indexPath)
        context.delete(breadObject)
        return true
    }
    
    func create() -> Bread {
        let bread = Bread(touch: Date.now,
                          directoryName: "임시 디렉토리",
                          title: "새로운 암기빵",
                          content: "",
                          separatedContent: [],
                          filterIndexes: Array(repeating: [], count: FilterColor.count))
        return bread
    }
    
    func bread(at indexPath: IndexPath) -> Bread {
        return fetchedResultController.object(at: indexPath)
    }
    
    func first() -> Bread? {
        return fetchedResultController.fetchedObjects?.first
    }
}

extension BreadDAO: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        NotificationCenter.default.post(name: .breadObjectsDidChange, object: nil)
    }
}

struct Page {
    static let sampleContent =
"""
근로계약에서 정한 휴식시간이나 대기시간이 근로시간에 속하는지 휴게시간에 속하는지는 특정업종이나 업무의 종류에 따라 일률적으로 판단할 것이 아니다. 이는 근로계약의 내용이나 해당 사업장에 적용되는 취업규칙과 단체협약의 규정, 근로자가 제공하는 업무의 내용과 해당 사업장의 구체적 업무 방식, 휴게 중인 근로자에 대한 사용자의 간섭이나 감독여부, 자유롭게 이용할 수 있는 휴게장소의 구비 여부, 그 밖에 근로자의 실질적 휴식이 방해되었다거나 사용자의 지휘, 감독을 인정할 만한 사정이 있는지와 그 정도 등 여러 사정을 종합하여 개별사안에 따라 구체적으로 판단하여야 한다.
"""
    static var sampleSeparatedContent: [String] {
        Page.sampleContent.components(separatedBy: ["\n", " "])
    }
    
    static var sampleFilterIndex: [[Int]] {
        [
            [0, 1, 3, 5, 7, 9],
            [15, 16, 17],
            [20, 21, 25],
            [28],
        ]
    }
    var content: String
}


