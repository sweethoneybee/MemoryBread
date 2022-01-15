//
//  GDDownloaderError.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/01.
//

import Foundation

enum GDDownloaderError: Error {
    case notConnectedToTheInternet
    case dataNotAllowed
    case hasNoPermissionToDriveReadOnly
    case tokenHasExpiredOrRevoked
    case unknownURLError(URLError)
    case unknown(NSError)
}

extension GDDownloaderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConnectedToTheInternet:
            return LocalizingHelper.errorNotConnectedToTheInternet
        case .dataNotAllowed:
            return LocalizingHelper.dataNotAllowed
        case .hasNoPermissionToDriveReadOnly:
            return LocalizingHelper.errorHasNoPermissionToGoogleDriveReadOnly
        case .tokenHasExpiredOrRevoked:
            return LocalizingHelper.errorTokenHasExpiredOrRevoked
        case .unknownURLError(let urlError):
            return String(format: LocalizingHelper.errorUnknownURLError, urlError.errorCode)
        case .unknown(let nserror):
            return String(format: LocalizingHelper.errorUnknown, nserror.code)
        }
    }
}
