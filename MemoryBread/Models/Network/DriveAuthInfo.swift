//
//  DriveAuthInfo.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/14.
//

import Foundation

struct DriveAuthInfo {
    enum Domain {
        case googleDrive
        
        var name: String {
            switch self {
            case .googleDrive: return "Google Drive"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .googleDrive: return UIImage(named: "logo_drive")
//            case .googleDrive: return UIImage(systemName: "pencil")
            }
        }
    }
    
    var domain: Domain
    var isSignIn: Bool
    var userEmail: String?
}
