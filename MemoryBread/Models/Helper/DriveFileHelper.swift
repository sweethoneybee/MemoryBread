//
//  DriveFileHelper.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/22.
//

import Foundation

final class DriveFileHelper {
    private init() {}

    static let shared = DriveFileHelper()

    private let drivePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!
    
    func localPath(of fileId: String, domain: DriveDomain) -> URL {
        switch domain {
        case .googleDrive:
            return drivePath.appendingPathComponent("googleDrive", isDirectory: true).appendingPathComponent(fileId)
        }
    }
    
    func fileExists(forId fileId: String, domain: DriveDomain) -> Bool {
        let fileURL = localPath(of: fileId, domain: domain)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

