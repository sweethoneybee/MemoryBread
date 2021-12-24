//
//  FileObject.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/12.
//

import Foundation

struct FileObject: Identifiable, Hashable {
    enum MimeType {
        case folder
        case file
        
        var image: UIImage? {
            switch self {
            case .folder: return UIImage(systemName: "folder.fill")
            case .file: return UIImage(systemName: "x.square.fill")
            }
        }
    }
    
    var id: String
    var name: String
    var size: Int64
    var mimeType: MimeType
    var domain: DriveDomain
    
    static func makeFileObjects(_ fileList: [GTLRDrive_File]) -> [Self] {
        return fileList.enumerated().map {
            return FileObject(
                id: $1.identifier ?? "",
                name: $1.name ?? "",
                size: $1.size?.int64Value ?? 0,
                mimeType: ($1.mimeType == "application/vnd.google-apps.folder") ? .folder : .file,
                domain: .googleDrive
            )
        }
    }
}
