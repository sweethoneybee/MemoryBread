//
//  Folder+CoreDataClass.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/22.
//
//

import Foundation
import CoreData

@objc(Folder)
public class Folder: NSManagedObject {
    /// 1) pinnedAtTop, pinnedAtBottom, index의 역할
    /// pinnedAtTop은 테이블뷰 상단에 고정된 Folder임을 나타내는 프로퍼티다.
    /// pinnedAtBottom은 테이블뷰 하단에 고정된 Folder임을 나타내는 프로퍼티다.
    /// index는 위의 두 프로퍼티를 사용하지 않고, Folder 간의 정렬 순서를 나타내기 위한 프로퍼티다.
    /// 테이블뷰 구현방식에 따라 달라질 수 있지만, index값은 절대적인 값이 아닌 상대적인 값으로
    /// 오름차순으로 정렬할 수 있게 값이 부여되면 된다.
    /// 현재는 index에 정수값을 부여하고 있고, index를 오름차순으로 Folder를 정렬한다.
    ///
    /// 2) 새로운 폴더 생성 시 index 값
    /// 폴더뷰 구현방식에 따라 달라질 수 있으나, 현재 index값 오름차순의 경우
    /// (pinnedAtTop을 제외한 제일 상단 Folder 객체의 index 값 - 1)이 새로운 폴더의 index 값이 된다.
    ///
    /// 3) 폴더뷰에서 순서 재정렬시 index값 변경사항
    /// 뷰에서 사용자가 재졍렬한 순서대로 Folder 객체들의 index값이 변경될 수 있다.

    @NSManaged public private(set) var id: UUID
    @NSManaged public var isSystemFolder: Bool
    @NSManaged public var pinnedAtTop: Bool
    @NSManaged public var pinnedAtBottom: Bool
    @NSManaged private var name: String
    @NSManaged public var index: Int64
    @NSManaged public var breads: NSSet?
    @NSManaged public var breadsCount: Int64
    
    init(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        isSystemFolder: Bool = false,
        pinnedAtTop: Bool = false,
        pinnedAtBottom: Bool = false,
        name: String,
        index: Int64,
        breads: NSSet?
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "Folder", in: context)!
        super.init(entity: entity, insertInto: context)
        self.id = id
        self.isSystemFolder = isSystemFolder
        self.pinnedAtTop = pinnedAtTop
        self.pinnedAtBottom = pinnedAtBottom
        self.name = name
        self.index = index
        self.breads = breads
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    @available(*, unavailable)
    public init() {
        fatalError("\(#function) not implemented")
    }
    
    @available(*, unavailable)
    public convenience init(context: NSManagedObjectContext) {
        fatalError("\(#function) not implemented")
    }
    
}

extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }
    
}

// MARK: Generated accessors for breads
extension Folder {

    @objc(addBreadsObject:)
    @NSManaged public func addToBreads(_ value: Bread)

    @objc(removeBreadsObject:)
    @NSManaged public func removeFromBreads(_ value: Bread)

    @objc(addBreads:)
    @NSManaged public func addToBreads(_ values: NSSet)

    @objc(removeBreads:)
    @NSManaged public func removeFromBreads(_ values: NSSet)

}

extension Folder : Identifiable {

}

extension Folder {
    var localizedName: String {
        guard isSystemFolder || pinnedAtTop else {
            return name
        }
        
        switch (isSystemFolder, pinnedAtTop) {
        case (true, true): return LocalizingHelper.allMemoryBreads
        case (false, true): return LocalizingHelper.defaultFolder
        case (true, false): return LocalizingHelper.trash
        default: return "Unknown Folder"
        }
    }
    
    func setName(_ name: String) {
        guard !name.isEmpty else {
            fatalError("Folder name cannot be empty.")
        }
        self.name = name
    }
}
