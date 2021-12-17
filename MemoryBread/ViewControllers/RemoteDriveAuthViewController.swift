//
//  RemoteDriveAuthViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/13.
//

import UIKit
import SnapKit

final class RemoteDriveAuthViewController: UIViewController {
    // MARK: - Views
    private var tableView: UITableView!
    
    // MARK: - Model
    private var model = DriveAuthModel()
    
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
            let alert = BasicAlert.makeConfirmAlert(title: LocalizingHelper.signOut, message: LocalizingHelper.signOutGoogleDrive) { [weak self] _ in
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
            print("로그인 되어있음!")
            return
        }
        
        model.signIn(at: index, modalView: self) { error in
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
            
            // present driveList view
        }
    }
}
