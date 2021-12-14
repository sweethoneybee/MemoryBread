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
    
    // MARK: - States
    private var googleAuthInfo = DriveAuthInfo(domain: .googleDrive, isSignIn: true, userEmail: "jsjphone8@gmail.com")
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        
        tableView.dataSource = self
        tableView.register(RemoteDriveCell.self, forCellReuseIdentifier: RemoteDriveCell.reuseIdentifier)
    }
}

// MARK: Set Views
extension RemoteDriveAuthViewController {
    private func setViews() {
        view.backgroundColor = .systemBackground
        
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
        
        cell.configure(using: googleAuthInfo)
        cell.delegate = self
        return cell
    }
}

// MARK: - RemoteDriveCellDelegate
extension RemoteDriveAuthViewController: RemoteDriveCellDelegate {
    func signInButtonTapped(_ cell: RemoteDriveCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            googleAuthInfo.isSignIn = true
            reloadCell(at: indexPath)
        }
    }
    
    func signOutButtonTapped(_ cell: RemoteDriveCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            googleAuthInfo.isSignIn = false
            reloadCell(at: indexPath)
        }
    }
    

}

