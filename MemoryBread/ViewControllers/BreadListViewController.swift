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
    
    private var tableView: UITableView!
    private var dataSource: BreadListViewController.DataSource!
    
    private var breadListController = BreadListController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "암기빵"
        navigationItem.backButtonDisplayMode = .minimal
        configureHierarchy()
        configureDataSource()
        addToolbar()
        
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let breadItems = breadListController.items
        var snapshot = NSDiffableDataSourceSnapshot<Section, BreadListController.BreadItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(breadItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Configure Views
extension BreadListViewController {
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    
    private func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func addToolbar() {
        let addItem = UIBarButtonItem(image: UIImage(systemName: "plus.app"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(addBread))
        navigationItem.rightBarButtonItem = addItem
    }
    
    @objc
    func addBread() {
        let newItem = breadListController.newBreadItem()
        var snapshot = dataSource.snapshot()
        if let firstItem = snapshot.itemIdentifiers.first {
            snapshot.insertItems([newItem], beforeItem: firstItem)
        } else {
            snapshot.appendItems([newItem], toSection: .main)
        }
        dataSource.apply(snapshot, animatingDifferences: true) {
            if let bread = BreadDAO.default.bread(at: 0) {
                let breadViewController = BreadViewController(bread: bread)
                self.navigationController?.pushViewController(breadViewController, animated: true)
            }
        }
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
        
        dataSource.didDeleteItemAt = { [weak self] index in
            self?.breadListController.deleteBread(at: index)
        }
    }
}

// MARK: - TableView Delegate
extension BreadListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let bread = BreadDAO.default.bread(at: indexPath.item) {
            let breadViewController = BreadViewController(bread: bread)
            navigationController?.pushViewController(breadViewController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
}

extension BreadListViewController {
    class DataSource: UITableViewDiffableDataSource<Section, BreadListController.BreadItem> {
        weak var dataController: BreadListController?
        var didDeleteItemAt: ((Int) -> Void)?
        
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                if let identifierToDelete = itemIdentifier(for: indexPath) {
                    var snapshot = self.snapshot()
                    snapshot.deleteItems([identifierToDelete])
                    apply(snapshot)
                    didDeleteItemAt?(indexPath.item)
                }
            }
        }
    }
}
