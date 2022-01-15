//
//  GDDownloader.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/11.
//

import Foundation

protocol GDDownloaderDelegate: AnyObject {
    func finishedDownload(_ file: FileObject, error: Error?)
    func downloadProgress(_ file: FileObject, totalBytesWritten: Int64)
}

/// Google Drive Downloader
final class GDDownloader {
    deinit {
        stopFetchingFileList()
        activeDownloads.values.forEach {
            $0.stopFetching()
        }
        DispatchQueue.global(qos: .background).async { [filesToBeDeleted] in
            let fileHelper = DriveFileHelper()
            filesToBeDeleted.forEach { file in
                let url = fileHelper.localPath(of: file)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    weak var delegate: GDDownloaderDelegate?
    
    /// Inject authorizer using GIDGoogleUser.authentication.fetcherAuthorizer()
    var authorizer: GTMFetcherAuthorizationProtocol? {
        get { return service.authorizer }
        set { service.authorizer = newValue }
    }
    
    private lazy var service: GTLRDriveService = {
        $0.shouldFetchNextPages = false
        $0.isRetryEnabled = true
        return $0
    }(GTLRDriveService())
    
    private let queryPageSize = 50
    private weak var fileListTicket: GTLRServiceTicket?
    
    /// Dictionary for guarding duplicate fetching
    /// Key is a GTLRDrive_File.id. Refer to
    /// [here](https://developers.google.com/drive/api/v3/reference/files)
    private var activeDownloads: [String: GDDownload] = [:]
    
    private var filesToBeDeleted: Set<FileObject> = []
    private var downloadFailedFiles: Set<FileObject> = []
}

// MARK: - File List Fetching
extension GDDownloader {
    func fetchFileList(atDirectory root: String?,
                       usingToken nextPageToken: String? = nil,
                       onCompleted: ((String?, [GTLRDrive_File]?, GDDownloaderError?)->Void)? = nil) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = queryPageSize
        query.pageToken = nextPageToken
        query.fields = "nextPageToken,files(mimeType,id,name,size)"
        
        let mimeType = "mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' or mimeType = 'application/vnd.google-apps.folder'"
        let path = "'\(root ?? "root")' in parents"
        let trashed = "trashed = false"
        query.q = "(\(mimeType)) and \(path) and \(trashed)"
        query.orderBy = "folder, name"
        
        fileListTicket = service.executeQuery(query) { ticket, result, error in
            /// GDDownloaderError
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    onCompleted?(nil, nil, .notConnectedToTheInternet)
                case .dataNotAllowed:
                    onCompleted?(nil, nil, .dataNotAllowed)
                default:
                    onCompleted?(nil, nil, .unknownURLError(urlError))
                }
                return
            }
            
            if let nserror = error as NSError? {
                switch nserror.code {
                case GTMSessionFetcherStatus.forbidden.rawValue:
                    onCompleted?(nil, nil, .hasNoPermissionToDriveReadOnly)
                case -10: /// OIDErrorCodeOAuthInvalidGrant
                    onCompleted?(nil, nil, .tokenHasExpiredOrRevoked)
                default:
                    onCompleted?(nil, nil, .unknown(nserror))
                }
                return
            }
            
            let fileList = result as? GTLRDrive_FileList
            onCompleted?(fileList?.nextPageToken, fileList?.files, nil)
        }
    }
    
    func stopFetchingFileList() {
        if let fileListTicket = fileListTicket {
            fileListTicket.cancel()
        }
    }
}

// MARK: - File Fetching
extension GDDownloader {
    func fetch(_ file: FileObject, to destinationURL: URL) {
        guard activeDownloads[file.id] == nil else {
            return
        }
        
        let id = file.id
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
        let downloadRequest = service.request(for: query)
        let fetcher = service.fetcherService.fetcher(with: downloadRequest as URLRequest)
        
        let download = GDDownload(file: file, fetcher: fetcher)
        download.destinationFileURL = destinationURL
        download.progressBlock = { [weak self] _, totalBytesWritten, _ in
            download.totalBytesWritten = totalBytesWritten
            self?.delegate?.downloadProgress(file, totalBytesWritten: totalBytesWritten)
        }
        
        activeDownloads[file.id] = download
        download.beginFetch { [weak self] data, error in
            self?.activeDownloads.removeValue(forKey: file.id)
    
            if let error = error {
                self?.downloadFailedFiles.insert(file)
                self?.delegate?.finishedDownload(file, error: error)
                return
            }
            
            self?.downloadFailedFiles.remove(file)
            self?.filesToBeDeleted.insert(file)
            self?.delegate?.finishedDownload(file, error: nil)
        }
    }
    
    func stopFetching(_ file: FileObject) {
        if let download = activeDownloads[file.id] {
            activeDownloads.removeValue(forKey: file.id)
            download.stopFetching()
        }
    }
    
    func activeDownload(forKey fileId: String) -> GDDownload? {
        return activeDownloads[fileId]
    }
    
    func isDownloaded(_ file: FileObject) -> Bool {
        return filesToBeDeleted.contains(file)
    }
    
    func isDownloading(_ file:FileObject) -> Bool {
        return activeDownload(forKey: file.id) != nil
    }
    
    func failedToDownload(_ file: FileObject) -> Bool {
        return downloadFailedFiles.contains(file)
    }
}
