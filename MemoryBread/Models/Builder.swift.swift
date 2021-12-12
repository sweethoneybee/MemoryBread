//
//  Builder.swift.swift
//  MemoryBread
//
//  Builder.swift's all code from https://techblog.woowahan.com/2715/
//

import Foundation

@dynamicMemberLookup
public struct Builder<Base: AnyObject> {

    private var base: Base

    public init(_ base: Base) {
        self.base = base
    }

    public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, Value>) -> (Value) -> Builder<Base> {
        { [base] value in
            base[keyPath: keyPath] = value
            return Builder(base)
        }
    }

    public func set<Value>(_ keyPath: ReferenceWritableKeyPath<Base, Value>, to value: Value) -> Builder<Base> {
        base[keyPath: keyPath] = value
        return Builder(base)
    }

    public func build() -> Base {
    }
}

public protocol Buildable {
    associatedtype Base: AnyObject
    var builder
}

public extension Buildable where Self: AnyObject {
    var builder
}

extension NSObject
