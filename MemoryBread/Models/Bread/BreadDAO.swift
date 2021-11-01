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
    
    // TODO: 임시 구현한 메소드라 삭제 필요
    func deleteAll() {
        let breads = fetchAll()
        for bread in breads {
            AppDelegate.viewContext.delete(bread)
        }
        
        save()
    }
    
    var mockBread: Bread {
        Bread(touch: Date.now,
              directoryName: "임시 폴더",
              title: "임시 타이틀",
              content: Page.sampleContent,
              separatedContent: Page.sampleSeparatedContent,
              filterIndexes: Array(repeating: [], count: FilterColor.count))
    }
}

struct Page {
    static let sampleContent =
"""
근로계약에서 정한 휴식시간이나 대기시간이 근로시간에 속하는지 휴게시간에 속하는지는 특정업종이나
업무의 종류에 따라 일률적으로 판단할 것이 아니다. 이는 근로계약의 내용이나 해당 사업장에 적용되는
취업규칙과 단체협약의 규정, 근로자가 제공하는 업무의 내용과 해당 사업장의 구체적 업무 방식, 휴게 중인
근로자에 대한 사용자의 간섭이나 감독여부, 자유롭게 이용할 수 있는 휴게장소의 구비 여부, 그 밖에 근로자의
실질적 휴식이 방해되었다거나 사용자의 지휘, 감독을 인정할 만한 사정이 있는지와 그 정도 등 여러 사정을
종합하여 개별사안에 따라 구체적으로 판단하여야 한다.
근로계약에서 정한 휴식시간이나 대기시간이 근로시간에 속하는지 휴게시간에 속하는지는 특정업종이나
업무의 종류에 따라 일률적으로 판단할 것이 아니다. 이는 근로계약의 내용이나 해당 사업장에 적용되는
취업규칙과 단체협약의 규정, 근로자가 제공하는 업무의 내용과 해당 사업장의 구체적 업무 방식, 휴게 중인
근로자에 대한 사용자의 간섭이나 감독여부, 자유롭게 이용할 수 있는 휴게장소의 구비 여부, 그 밖에 근로자의
실질적 휴식이 방해되었다거나 사용자의 지휘, 감독을 인정할 만한 사정이 있는지와 그 정도 등 여러 사정을
종합하여 개별사안에 따라 구체적으로 판단하여야 한다.
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

