//
//  RemoteDriveAuthViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/13.
//

import UIKit
import SnapKit
import CoreData

final class RemoteDriveAuthViewController: UIViewController {
    // MARK: - Views
    private var tableView: UITableView!
    
    // MARK: - Model
    private var model = DriveAuthModel()
    private var gdDownloader: GDDownloader?
    private var writeContext: NSManagedObjectContext
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RemoteDriveCell.self, forCellReuseIdentifier: RemoteDriveCell.reuseIdentifier)

        model.changedDatasource = { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gdDownloader = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(context: NSManagedObjectContext) {
        self.writeContext = context
        super.init(nibName: nil, bundle: nil)
    }
}

// MARK: Set Views
extension RemoteDriveAuthViewController {
    private func setViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = LocalizingHelper.import
        tableView = UITableView()
        view.addSubview(tableView)
        
        configureLayouts()
    }
    
    private func configureLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - Update Views
extension RemoteDriveAuthViewController {
    private func reloadCell(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - UITableViewDataSource
extension RemoteDriveAuthViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RemoteDriveCell.reuseIdentifier, for: indexPath) as? RemoteDriveCell else {
            return UITableViewCell()
        }
        
        let authInfo = model.authInfo(at: indexPath.item)
        cell.configure(using: authInfo)
        cell.delegate = self
        return cell
    }
}

// MARK: - RemoteDriveCellDelegate
extension RemoteDriveAuthViewController: RemoteDriveCellDelegate {
    func signOutButtonTapped(_ cell: RemoteDriveCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let alert = BasicAlert.makeCancelAndConfirmAlert(title: LocalizingHelper.signOut, message: LocalizingHelper.signOutGoogleDrive) { [weak self] _ in
                self?.model.signOut(at: indexPath.item)
                self?.reloadCell(at: indexPath)
            }
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension RemoteDriveAuthViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let index = indexPath.item
        if model.isSignIn(at: index) {
            presentFileListViewController(of: model.drive(at: index))
            return
        }
        
        model.signIn(at: index, modalView: self) { [weak self] error in
            guard let self = self else {
                return
            }
            
            // TODO: 로그인 에러 선언하여 처리 필요
            if let error = error {
//                switch error {
//                case press cancel:
//                    show alert "you press cancel"
//                case error while signing:
//                    show alert "error whilte sign"
//                case sign error:
//                    show alert "google sign error"
//                }
                print("로그인실패에러=\(error)")
                return
            }
            
            self.presentFileListViewController(of: self.model.drive(at: index))
        }
    }
}

// MARK: - Presenting VC
extension RemoteDriveAuthViewController {
    func presentFileListViewController(of domain: DriveDomain) {
        let fileListVC: UIViewController
        switch domain {
        case .googleDrive:
            gdDownloader = GDDownloader()
            gdDownloader?.authorizer = DriveAuthStorage.shared.googleDrive
            let vc = DriveFileListViewController(context: writeContext, dirID: "root", dirName: nil)
            vc.downloader = gdDownloader
            fileListVC = vc
        }
        navigationController?.pushViewController(fileListVC, animated: true)
    }
}
