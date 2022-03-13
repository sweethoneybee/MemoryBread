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
            if let ret = UserDefaults.standard.object(forKey: key) as? T {
                return ret
            }
            UserDefaults.standard.set(defaultValue, forKey: key)
            return defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct AutoIncreaseId {
    @UserDefault<Int64>(key: "breadId", defaultValue: 0)
    private(set) var breadId: Int64
    
    var wrappedValue: Int64 {
        mutating get {
            let value = breadId
            breadId = value + 1
            return value
        }
    }
}

final class UserManager {
    @AutoIncreaseId
    static var autoIncreaseId: Int64
    
    @UserDefault<Bool>(key: "firstLaunch", defaultValue: true)
    static var firstLaunch: Bool
    
    @UserDefault<String>(key: "defaultFolderID", defaultValue: UUID().uuidString)
    static var defaultFolderID: String
    
    @UserDefault<String>(key: "trashFolderID", defaultValue: UUID().uuidString)
    static var trashFolderID: String
}
