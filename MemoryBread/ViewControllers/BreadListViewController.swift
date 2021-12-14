//
//  BreadListViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
// 'ImplementingModernCollectionViews' sample code from Apple
// 

import UIKit
import SnapKit

final class BreadListViewController: UIViewController {
    enum Section {
        case main
    }
    
    let reuseIdentifier = "reuse-identifier-bread-list-view"

    // MARK: - Views
    private var tableView: UITableView!
    private var headerLabel: UILabel!
    private var addBreadButton: UIButton!
    
    // MARK: - Properties
    private var dataSource: BreadListViewController.DataSource!
    private var isAdding = false

    // MARK: - Model
    private var breadListController = BreadListModel()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        configureDataSource()
        tableView.delegate = self

        let breadItems = breadListController.items
        var snapshot = NSDiffableDataSourceSnapshot<Section, BreadListModel.BreadItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(breadItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
        
        headerLabel.text = String(format: LocalizingHelper.numberOfMemoryBread, breadItems.count)
        
        NotificationCenter.default.addObserver(self, selector: #selector(breadObjectsDidChange), name: .breadObjectsDidChange, object: nil)
    }
    
    @objc
    private func breadObjectsDidChange() {
        let items = breadListController.items
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, BreadListModel.BreadItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
        
        headerLabel.text = String(format: LocalizingHelper.numberOfMemoryBread, items.count)
    }
}

// MARK: - Configure Views
extension BreadListViewController {
    private func setViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "app_title".localized
        navigationItem.backButtonDisplayMode = .minimal
        
        headerLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 14, weight: .light)
            $0.textAlignment = .center
            $0.textColor = .black
            $0.frame.size.height = 30
        }
        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableHeaderView = headerLabel
        view.addSubview(tableView)
        
        addBreadButton = UIButton().then {
            $0.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            $0.tintColor = .systemPink
            $0.addTarget(self, action: #selector(addBreadButtonTouched), for: .touchUpInside)
        }
        view.addSubview(addBreadButton)
        
        configureHierarchy()
        addToolbar()
    }
    
    private func configureHierarchy() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addBreadButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        addBreadButton.imageView?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func addToolbar() {
        let addBreadFromRemoteDriveItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(addBreadFromRemoteDriveTouched))
        
        let settingItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(settingButtonTouched))
        navigationItem.rightBarButtonItems = [settingItem, addBreadFromRemoteDriveItem]
    }
    
    @objc
    func addBreadButtonTouched() {
        guard isAdding == false else { return }
        isAdding = true
        let breadViewController = BreadViewController(bread: breadListController.createBread())
        navigationController?.pushViewController(breadViewController, animated: true)
        isAdding = false
    }
    
    @objc
    func addBreadFromRemoteDriveTouched() {
        print("드라이브에서 다운로드 버튼 눌림")
    }
    
    @objc
    func settingButtonTouched() {
        print("세팅버튼 눌림")
        let vc = RemoteDriveAuthViewController()
        present(vc, animated: true)
    }
}

// MARK: - Data Source
extension BreadListViewController {
    private func configureDataSource() {
        let titleAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
        let dateAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)]
        let bodyAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .light)]
        
        let dateHelper = DateHelper()
        dataSource = DataSource(tableView: tableView) {
            tableView, indexPath, breadItem in
            let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
            
            var content = cell.defaultContentConfiguration()
            let titleAttributedString = NSAttributedString(string: breadItem.title, attributes: titleAttribute)
            content.attributedText = titleAttributedString
            content.textProperties.numberOfLines = 1
            
            let dateString = dateHelper.string(from: breadItem.date)
            
            let secondaryAttributedString = NSMutableAttributedString(string: dateString + " ", attributes: dateAttribute)
            secondaryAttributedString.append(NSAttributedString(string: breadItem.body, attributes: bodyAttribute))
            
            content.secondaryAttributedText = secondaryAttributedString
            content.secondaryTextProperties.numberOfLines = 1
            
            cell.contentConfiguration = content
            return cell
        }
        
        dataSource.deleteBlock = { [weak self] indexPath in
            self?.breadListController.deleteBread(at: indexPath)
        }
    }
}

// MARK: - TableView Delegate
extension BreadListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let breadViewController = BreadViewController(bread: breadListController.bread(at: indexPath))
        navigationController?.pushViewController(breadViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
}

extension BreadListViewController {
    class DataSource: UITableViewDiffableDataSource<Section, BreadListModel.BreadItem> {
        var deleteBlock: ((IndexPath) -> (Void))?
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                deleteBlock?(indexPath)
            }
        }
    }
}
