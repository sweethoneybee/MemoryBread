//
//  DriveFileListViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/19.
//

import UIKit
import SnapKit

final class DriveFileListViewController: UIViewController {
    
    // MARK: - State
    private var isFetching = false {
        didSet {
            if isFetching {
                activityIndicator.startAnimating()
                return
            }
            activityIndicator.stopAnimating()
        }
    }
    private var isOpeningFile = false
    var currentDirName: String
    
    // MARK: - Views
    private var tableView: UITableView!
    private var activityIndicator: UIActivityIndicatorView!
    private var noFilesHereLabel: UILabel!
    
    // MARK: - Model
    weak var downloader: GDDownloader?
    var currentDirId: String
    private var files = OrderedDictionary<String, FileObject>()
    private var nextPageToken: String?
    private var fileHelper = DriveFileHelper()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FileListCell.self, forCellReuseIdentifier: FileListCell.reuseIdentifier)
        
        fetchFileList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        downloader?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isFetching {
            downloader?.stopFetchingFileList()
        }
    }
    
    init(dirID: String, dirName: String? = nil) {
        self.currentDirId = dirID
        self.currentDirName = dirName ?? "Google Drive"
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented DriveFileListviewController")
    }
}

// MARK: - Set Views
extension DriveFileListViewController {
    private func setViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = currentDirName
        
        tableView = UITableView().then {
            view.addSubview($0)
        }
        
        activityIndicator = UIActivityIndicatorView(style: .medium).then {
            tableView.addSubview($0)
        }
        
        noFilesHereLabel = UILabel().then {
            $0.textAlignment = .center
            $0.font = .preferredFont(forTextStyle: .headline)
            $0.isHidden = true
            $0.text = LocalizingHelper.noFilesAreHere
            view.addSubview($0)
        }
        
        // layouts
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }
        
        noFilesHereLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func updateUI(isFileExist: Bool) {
        tableView.isHidden = !isFileExist
        noFilesHereLabel.isHidden = isFileExist
        tableView.reloadData()
    }
    
    private func reload(at index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
}

// MARK: - Business Logic
extension DriveFileListViewController {
    private func fetchFileList() {
        guard isFetching == false,
              let downloader = downloader else {
                  return
              }
        isFetching = true
        downloader.fetchFileList(atDirectory: currentDirId) { [weak self] nextPageToken, fetchedFileList, error in
            defer {
                self?.isFetching = false
            }
            guard let self = self else {
                return
            }
            
            if let error = error {
                print("파일 리스트 불러오는 중 에러=\(error)")
                let alert = BasicAlert.makeErrorAlert(message: LocalizingHelper.failedToGetFileList) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                self.present(alert, animated: true)
                return
            }
            
            guard let fileList = fetchedFileList else {
                print("파일리스트 받은 게 없음")
                let alert = BasicAlert.makeErrorAlert(message: LocalizingHelper.failedToGetFileList) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                self.present(alert, animated: true)
                return
            }
            
            self.nextPageToken = nextPageToken
            self.files = OrderedDictionary<String, FileObject>.makeContainer(base: FileObject.makeFileObjects(fileList))
            self.updateUI(isFileExist: self.files.count != 0)
        }
    }
    
    private func fetchFileList(usingToken nextPageToken: String?) {
        guard isFetching == false,
              nextPageToken != nil,
              let downloader = downloader else {
                  return
              }
        
        isFetching = true
        downloader.fetchFileList(atDirectory: currentDirId, usingToken: nextPageToken) { [weak self] nextPageToken, fetchedFileList, error in
            defer {
                self?.isFetching = false
            }
            guard let self = self else {
                return
            }
            
            if let error = error {
                print("파일 리스트 불러오는 중 에러=\(error)")
                let alert = BasicAlert.makeErrorAlert(message: LocalizingHelper.failedToGetFileList) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                self.present(alert, animated: true)
                return
            }
            
            guard let fileList = fetchedFileList else {
                print("파일리스트 받은 게 없음")
                let alert = BasicAlert.makeErrorAlert(message: LocalizingHelper.failedToGetFileList) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                self.present(alert, animated: true)
                return
            }
            
            self.nextPageToken = nextPageToken
            self.files.append(contentsOf: FileObject.makeFileObjects(fileList))
            self.updateUI(isFileExist: self.files.count != 0)
        }
    }
}

// MARK: - UITableViewDataSource
extension DriveFileListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FileListCell.reuseIdentifier, for: indexPath) as? FileListCell,
              let file = files.value(at: indexPath.item) else {
                  return UITableViewCell()
              }
        
        let download = downloader?.activeDownload(forKey: file.id)
        let fileExists = downloader?.isDownloaded(file) ?? false
        cell.configure(using: file, download: download, isExist: fileExists)
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DriveFileListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        if let file = files.value(at: indexPath.item) {
            switch file.mimeType {
            case .file:
                if !(downloader?.isDownloaded(file) ?? false),
                   !(downloader?.isDownloading(file) ?? false) {
                    let destinationURL = fileHelper.localPath(of: file)
                    downloader?.fetch(file, to: destinationURL)
                    reload(at: indexPath.item)
                }
            case .folder:
                let dflVC = DriveFileListViewController(dirID: file.id, dirName: file.name)
                dflVC.downloader = downloader
                navigationController?.pushViewController(dflVC, animated: true)
            }
        }
    }
}

// MARK: - FileListCellDelegate
extension DriveFileListViewController: FileListCellDelegate {
    func cancelButtonTapped(_ cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell),
           let file = files.value(at: indexPath.item) {
            downloader?.stopFetching(file)
            reload(at: indexPath.item)
        }
    }
    
    func openButtonTapped(_ cell: UITableViewCell) {
        guard isOpeningFile == false else  {
            return
        }
        isOpeningFile = true
        if let indexPath = tableView.indexPath(for: cell),
           let file = files.value(at: indexPath.item ) {
            let filePath = fileHelper.localPath(of: file)
            ExcelReader.readXLSXFile(at: filePath) { [weak self] result in
                guard let self = self else { return }
                
                defer {
                    self.isOpeningFile = false
                }
                
                switch result {
                case .failure(let error):
                    switch error {
                    case .failToReadXLSXFile:
                        print("데이터 읽기 실패")
                    case .XLSXFileIsNotVaild:
                        print("워크시트 파싱 실패")
                    case .XLSXFileIsEmpty:
                        print("XLSX 파일이 비어있음")
                    }
                case .success(let rows):
                    let alert = BasicAlert.makeConfirmAlert(title: LocalizingHelper.creatingBread, message: String(format: LocalizingHelper.creatingBreadFromFile, file.name, rows.count))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - GDDownloaderDelegate
extension DriveFileListViewController: GDDownloaderDelegate {
    func finishedDownload(_ file: FileObject, error: Error?) {
        if let index = files.index(forKey: file.id) {
            reload(at: index)
        }
    }
    
    func downloadProgress(_ file: FileObject, totalBytesWritten: Int64) {
        if let index = files.index(forKey: file.id),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FileListCell {
            cell.updateProgress(Float(totalBytesWritten) / Float(file.size), totalBytesWritten: totalBytesWritten, totalSize: file.size)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension DriveFileListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + tableView.frame.height) >= scrollView.contentSize.height {
            fetchFileList(usingToken: nextPageToken)
        }
    }
}