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
    var totalBytesWritten: Int64 = 0
    var progress: Float {
        return Float(totalBytesWritten) / Float(file.size)
    }
    
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
    
    func beginFetch(completionHandler: @escaping (Data?, Error?) -> ()) {
        fetcher.beginFetch(completionHandler: completionHandler)
    }
    
    func stopFetching() {
        fetcher.stopFetching()
    }
}
