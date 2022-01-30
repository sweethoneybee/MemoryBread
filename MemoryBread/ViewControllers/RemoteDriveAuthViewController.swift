//
//  RemoteDriveAuthViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/13.
//

import UIKit
import SnapKit
import CoreData
import GoogleSignIn

final class RemoteDriveAuthViewController: UIViewController {
    // MARK: - Views
    private var tableView: UITableView!
    
    // MARK: - Model
    var currentFolderName: String?
    
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

        model.driveAuthStorageHasChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reSigningInGoogleDriveIsNeeded), name: .reSigningInGoogleDriveIsNeeded, object: nil)
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
    
    // Notification Method
    @objc
    private func reSigningInGoogleDriveIsNeeded() {
        let googleDriveIndex = DriveDomain.googleDrive.rawValue
        model.signOut(at: googleDriveIndex)
        reloadCell(at: IndexPath(row: googleDriveIndex, section: 0))
    }
}

// MARK: Set Views
extension RemoteDriveAuthViewController {
    private func setViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = LocalizingHelper.import
        tableView = UITableView().then {
            $0.isScrollEnabled = false
        }
        view.addSubview(tableView)
        
        configureLayouts()
        
        addBarButtonItem()
    }
    
    private func configureLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func addBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(
            title: LocalizingHelper.cancel,
            style: .plain,
            target: self,
            action: #selector(cancelBarButtonTapped)
        )
        navigationItem.leftBarButtonItem = cancelBarButtonItem
    }
}

// MARK: - Update Views
extension RemoteDriveAuthViewController {
    private func reloadCell(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - Target Action
extension RemoteDriveAuthViewController {
    @objc
    private func cancelBarButtonTapped() {
        dismiss(animated: true)
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
    func signInButtonTapped(_ cell: RemoteDriveCell) {
        if let index = tableView.indexPath(for: cell)?.item {
            model.signIn(at: index, modalView: self) { [weak self] error in
                guard let self = self else {
                    return
                }
                
                if let error = error as NSError? {
                    self.handle(error)
                    return
                }
                
                self.presentFileListViewController(of: self.model.drive(at: index))
            }
        }
    }
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
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return model.isSignIn(at: indexPath.item)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let index = indexPath.item
        if model.isSignIn(at: index) {
            presentFileListViewController(of: model.drive(at: index))
            return
        }
    }
}

// MARK: - Error handling
extension RemoteDriveAuthViewController {
    private func handle(_ error: NSError) {
        
        let errorMessage: String
        switch error {
        case GIDSignInError.canceled:
            errorMessage = LocalizingHelper.errorSignCanceled
        case GIDSignInError.keychain:
            errorMessage = LocalizingHelper.errorKeychain
        case GIDSignInError.hasNoAuthInKeychain:
            errorMessage = LocalizingHelper.errorNoAuthInKeyChain
        case GIDSignInError.scopesAlreadyGranted:
            errorMessage = LocalizingHelper.errorScopesAlreadyGranted
        case GIDSignInError.noCurrentUser:
            errorMessage = LocalizingHelper.errorNoCurrentUser
        case GIDSignInError.EMM:
            errorMessage = LocalizingHelper.errorEMM
        default:
            /// OIDErrorCodeOAuth.accessDenied
            if error.code == -1 {
                errorMessage = LocalizingHelper.errorAccessDenied
                break
            }
            errorMessage = String(format: LocalizingHelper.errorUnknown, error.code)
        }
        
        let alert = BasicAlert.makeErrorAlert(message: errorMessage)
        present(alert, animated: true)
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
            vc.currentFolderName = currentFolderName
            fileListVC = vc
        }
        navigationController?.pushViewController(fileListVC, animated: true)
    }
}
