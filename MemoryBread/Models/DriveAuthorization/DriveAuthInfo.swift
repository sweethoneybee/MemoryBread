//
//  DriveAuthInfo.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/14.
//

import Foundation

final class DriveAuthStorage: NSObject {
    static var shared = DriveAuthStorage()
    @objc dynamic var googleDrive: GTMFetcherAuthorizationProtocol?
}

struct DriveAuthInfo {
    enum Domain: Int {
        case googleDrive
        
        var name: String {
            switch self {
            case .googleDrive: return "Google Drive"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .googleDrive: return UIImage(named: "logo_drive")
            }
        }
    }
    
    var domain: Domain
    var isSignIn: Bool
    var userEmail: String?
}

