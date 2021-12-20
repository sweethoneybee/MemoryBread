//
//  OrderedDictionary.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/20.
//

import Foundation


/// OrderedDictionary는 딕셔너리와 유사한 자료형으로 조회에 상수시간이 걸립니다.
/// T 값을 바탕으로 값, 인덱스를 조회할 수 있습니다.
/// 각 E 를 개별적으로 수정할 수 없고, 읽기만 가능합니다.
/// E 를 FIFO 형태로 붙일 수 있습니다.
struct OrderedDictionary<T, E> where E: Identifiable, T == E.ID {
    private var keyTable: [T] = []
    private var values: [T: E] = [:]
    private var indexes: [T: Int] = [:]
    
    static func makeContainer(base baseElements: [E]) -> Self {
        var ret = OrderedDictionary<T, E>()
        ret.keyTable = baseElements.map { $0.id }
        ret.values = Dictionary<T, E>(uniqueKeysWithValues: zip(ret.keyTable, baseElements))
        ret.indexes = Dictionary<T, Int>(uniqueKeysWithValues: zip(ret.keyTable, 0..<ret.keyTable.count))
        return ret
    }
    
    // MARK: - Privates
    private func isOutOfRange(_ index: Int) -> Bool {
        return keyTable.count <= index
    }
    
    // MARK: - Read Only Interfaces
    var count: Int {
        get { return keyTable.count }
    }
    
    subscript(index: T) -> E? {
        get { return values[index] }
    }
    
    func value(at index: Int) -> E? {
        guard isOutOfRange(index) == false else {
            return nil
        }
        return values[keyTable[index]]
    }
    
    func index(forKey key: T) -> Int? {
        return indexes[key]
    }
    
    // MARK: - Write Interfaces
    mutating func append(contentsOf newElements: [E]) {
        let newKeys = newElements.map { $0.id }
        let newIndexes = keyTable.count..<keyTable.count + newKeys.count
        zip(newKeys, newIndexes).forEach { (key, index) in
            indexes[key] = index
        }
        
        keyTable.append(contentsOf: newKeys)
        zip(newKeys, newElements).forEach { (key, value) in
            values[key] = value
        }
    }
}


