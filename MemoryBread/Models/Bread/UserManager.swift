//
//  UserManager.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/03.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
    var key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct AutoIncreaseId {
    @UserDefault<Int64>(key: "breadId", defaultValue: 0)
    private(set) var projectedValue: Int64
    
    var wrappedValue: Int64 {
        mutating get {
            let value = projectedValue
            projectedValue = value + 1
            return value
        }
    }
}

final class UserManager {
    @AutoIncreaseId
    static var autoIncreaseId: Int64
}
