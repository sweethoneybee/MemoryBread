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

final class UserManager {
    @UserDefault<Bool>(key: "firstLaunch", defaultValue: true)
    static var firstLaunch: Bool
    
    @UserDefault<String>(key: "defaultFolderID", defaultValue: UUID().uuidString)
    static var defaultFolderID: String
    
    @UserDefault<String>(key: "trashFolderID", defaultValue: UUID().uuidString)
    static var trashFolderID: String
    
    @UserDefault<Int>(key: "wordSize", defaultValue: WordSize.medium.rawValue)
    static var wordSize: Int
    
    @UserDefault<Bool>(key: "didNewLineMigration", defaultValue: false)
    static var didNewLineMigration: Bool
}
