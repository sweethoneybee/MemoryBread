//
//  GDDownloader.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/11.
//

import Foundation

//protocol GDDownloaderDelegate: AnyObject {
//    func finishedDownload(_ fileObject: FileObject, error: Error?)
//    func downloadProgress(_ fileOjbect: FileObject, totalBytesWritten: Int64)
//}

/// Google Drive Downloader
final class GDDownloader {
    private init() {
        service = GTLRDriveService()
        service.isRetryEnabled = true
    }
    
    static let shared = GDDownloader()
        
    /// Dictionary for guarding duplicate fetching
    /// Key is a GTLRDrive_File.id. Refer to
    /// [here](https://developers.google.com/drive/api/v3/reference/files)
    var activeFetchers: [String: GTMSessionFetcher] = [:]
    
    /// Inject authorizer using GIDGoogleUser.authentication.fetcherAuthorizer()
    var authorizer: GTMFetcherAuthorizationProtocol? {
        get { return service.authorizer }
        set { service.authorizer = newValue }
    }
    
    private let service: GTLRDriveService
    private let drivePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!.appendingPathComponent("googleDrive", isDirectory: true)
    
    private func localPath(for id: String) -> URL {
        return drivePath.appendingPathComponent(id)
    }
    
//    private func isExistFile(_ file: FileObject) -> Bool
//    func fetchFileList()
//    func fetch(_ file: FileObject)
}
