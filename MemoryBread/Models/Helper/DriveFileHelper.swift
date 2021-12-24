//
//  DriveFileHelper.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/22.
//

import Foundation

struct DriveFileHelper {
    func localPath(of file: FileObject) -> URL {
        let fileId = file.id
        let tmpPath = URL(fileURLWithPath: NSTemporaryDirectory())
        switch file.domain {
        case .googleDrive:
            return tmpPath.appendingPathComponent("googleDrive", isDirectory: true).appendingPathComponent(fileId)
        }
    }
}

