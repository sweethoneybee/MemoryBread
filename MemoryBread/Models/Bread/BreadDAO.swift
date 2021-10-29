//
//  BreadDAO.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/27.
//

import Foundation

final class BreadDAO {
    private func Log(title: String, error: Error) {
        NSLog("\(title) failed. Error=\(error)")
    }
    
    func fetchAll() -> [Bread] {
        let request = Bread.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "touch", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        let fetchedBread: [Bread]
        do {
            fetchedBread = try AppDelegate.viewContext.fetch(request)
        } catch {
            Log(title: "FetchAll()", error: error)
            fetchedBread = [Bread]()
        }
        
        return fetchedBread
    }
    
    @discardableResult
    func save() -> Bool {
        do {
            try AppDelegate.viewContext.save()
        } catch {
            Log(title: "save()", error: error)
            return false
        }
        return true
    }
    
    @discardableResult
    func delete(_ bread: Bread) -> Bool {
        AppDelegate.viewContext.delete(bread)
        return save()
    }
}
