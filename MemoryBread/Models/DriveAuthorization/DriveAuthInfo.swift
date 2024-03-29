//
//  DriveAuthInfo.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/14.
//

import Foundation
import Combine
final class DriveAuthStorage: NSObject {
    static var shared = DriveAuthStorage()
    var googleDrive: CurrentValueSubject<GTMFetcherAuthorizationProtocol?, Never> = .init(nil)
}

enum DriveDomain: Int {
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

struct DriveAuthInfo {
    var domain: DriveDomain
    var isSignIn: Bool
    var userEmail: String?
}

