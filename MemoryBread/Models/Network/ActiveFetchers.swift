//
//  ActiveFetchers.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/13.
//

import Foundation

final class ActiveFetchers {
    /// Dictionary for guarding duplicate fetching
    /// Key is a GTLRDrive_File.id. Refer to
    /// [here](https://developers.google.com/drive/api/v3/reference/files)
    @MainThreadJob<[String: GTMSessionFetcher]>(value: [:])
    static var GTMSessionFetchers
}

@propertyWrapper
struct MainThreadJob<T> {
    var value: T
    
    var wrappedValue: T {
        get {
            if Thread.isMainThread {
                return value
            }
            fatalError("MainThreadJob propertyWrapper error")
        }
        set {
            if Thread.isMainThread {
                value = newValue
                return
            }
            fatalError("MainThreadJob propertyWrapper error")
        }
    }
}
