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

    private let fileManager = FileManager.default
    
    func localPath(of fileId: String, domain: DriveDomain) -> URL {
        let tmpPath = URL(fileURLWithPath: NSTemporaryDirectory())
        switch domain {
        case .googleDrive:
            return tmpPath.appendingPathComponent("googleDrive", isDirectory: true).appendingPathComponent(fileId)
        }
    }
    
    func fileExists(forId fileId: String, domain: DriveDomain) -> Bool {
        let fileURL = localPath(of: fileId, domain: domain)
        return fileManager.fileExists(atPath: fileURL.path)
    }
}

