//
//  GDDownload.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/18.
//

import Foundation

final class GDDownload {
    private var file: FileObject
    private var fetcher: GTMSessionFetcher
    
    var size: Int64 {
        return file.size
    }
    var totalBytesWritten: Int64 = 0 {
        didSet {
            progress = Float(totalBytesWritten) / Float(file.size)
        }
    }
    var progress: Float = 0
    
    var progressBlock: ((Int64, Int64, Int64)->())? {
        get { return fetcher.downloadProgressBlock }
        set { fetcher.downloadProgressBlock  = newValue }
    }
    
    var destinationFileURL: URL? {
        get { return fetcher.destinationFileURL }
        set { fetcher.destinationFileURL = newValue }
    }
    
    init(file: FileObject, fetcher: GTMSessionFetcher) {
        self.file = file
        self.fetcher = fetcher
    }
}

extension GDDownload {
    func beginFetch(completionHandler: @escaping (Data?, Error?) -> ()) {
        fetcher.beginFetch(completionHandler: completionHandler)
    }
    
    func stopFetching() {
        fetcher.stopFetching()
    }
}
