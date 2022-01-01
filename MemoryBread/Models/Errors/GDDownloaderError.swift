//
//  GDDownloaderError.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/01.
//

import Foundation

enum GDDownloaderError: Error {
    case notConnectedToTheInternet
    case hasNoPermissionToDriveReadOnly
    case unknown
}

extension GDDownloaderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConnectedToTheInternet:
            return LocalizingHelper.errorNotConnectedToTheInternet
        case .hasNoPermissionToDriveReadOnly:
            return LocalizingHelper.errorHasNoPermissionToGoogleDriveReadOnly
        case .unknown:
            return String(format: LocalizingHelper.errorUnknown, (self as NSError).code)
        }
    }
}
