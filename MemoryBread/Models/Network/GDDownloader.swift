//
//  GDDownloader.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/11.
//

import Foundation

protocol GDDownloaderDelegate: AnyObject {
    func finishedDownload(_ fileObject: FileObject, error: Error?)
    func downloadProgress(_ fileOjbect: FileObject, totalBytesWritten: Int64)
}

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
    
    weak var delegate: GDDownloaderDelegate?
    private weak var fileListTicket: GTLRServiceTicket?

    private let service: GTLRDriveService
    private let drivePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!.appendingPathComponent("googleDrive", isDirectory: true)
    
    private func localPath(for id: String) -> URL {
        return drivePath.appendingPathComponent(id)
    }
    
    private func isExistFile(_ file: FileObject) -> Bool {
        let destinationURL = self.localPath(for: file.id)
        return FileManager.default.fileExists(atPath: destinationURL.path)
    }
    
    func fetchFileList(at root: String,
                       usingToken nextPageToken: String? = nil,
                       onCompleted: ((String?, [GTLRDrive_File]?, Error?)->Void)? = nil) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 50
        query.pageToken = nextPageToken
        query.fields = "nextPageToken,files(mimeType,id,name,size)"
        
        let mimeType = "mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' or mimeType = 'application/vnd.google-apps.folder' or mimeType = 'application/pdf'"
        let path = "'\(root)' in parents"
        let trashed = "trashed = false"
        query.q = "(\(mimeType)) and \(path) and \(trashed)"
        query.orderBy = "folder, name"
        
        fileListTicket = service.executeQuery(query) { ticket, result, error in
            if let error = error {
                onCompleted?(nil, nil, error)
                return
            }
            
            let fileList = result as? GTLRDrive_FileList
            onCompleted?(fileList?.nextPageToken, fileList?.files, nil)
        }
    }
  
    func fetch(_ file: FileObject) {
        guard activeFetchers[file.id] == nil else {
            return
        }
        
        let id = file.id
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
        
        let downloadRequest = service.request(for: query)
        let fetcher = service.fetcherService.fetcher(with: downloadRequest as URLRequest)
        fetcher.destinationFileURL = self.localPath(for: id)
        fetcher.downloadProgressBlock = { _, totalBytesWritten, _ in
            self.delegate?.downloadProgress(file, totalBytesWritten: totalBytesWritten)
        }
        
        activeFetchers[file.id] = fetcher
        fetcher.beginFetch { data, error in
            defer {
                self.activeFetchers.removeValue(forKey: file.id)
            }
            
            if let error = error {
                self.delegate?.finishedDownload(file, error: error)
            }
            
            self.delegate?.finishedDownload(file, error: nil)
        }
    }
    
    func stopFetching(_ file: FileObject) {
        if let fetcher = activeFetchers[file.id] {
            fetcher.stopFetching()
            activeFetchers.removeValue(forKey: file.id)
        }
    }
    
    func stopFetchingFileList() {
        if let fileListTicket = fileListTicket {
            fileListTicket.cancel()
        }
    }
}
