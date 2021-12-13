//
//  RemoteDriveAuthViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/13.
//

import UIKit
import SnapKit

final class RemoteDriveAuthViewController: UIViewController {
    required init?(coder: NSCoder) {
        fatalError("not imeplemented")
    }
    
    // MARK: - Views
    private var tableView: UITableView!
    
    // MARK: - States
    private var googleDriveAuth = AuthInfo(isAvailable: false, user: nil)
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        
        tableView.delegate = self
        tableView.dataSource = self
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
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Definitions
extension RemoteDriveAuthViewController {
    struct AuthInfo {
        var isAvailable: Bool
        var user: String?
    }
}

// MARK: - UITableViewDataSource
extension RemoteDriveAuthViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

// MARK: - UITableViewDelegate
extension RemoteDriveAuthViewController: UITableViewDelegate {
    
}

