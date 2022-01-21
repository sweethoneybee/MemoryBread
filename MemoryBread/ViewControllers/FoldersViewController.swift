//
//  FoldersViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/01/19.
//

import UIKit
import CoreData

final class FoldersViewController: UIViewController {
    static let reuseIdentifier = "folders-view-controller-reuse-identifier"
    enum Section {
        case main
    }
    
    // MARK: - Views
    private var tableView: UITableView!
    private var dataSource: UITableViewDiffableDataSource<Section, Int>!

    // MARK: - Buttons
    private var addFolderItem: UIBarButtonItem!
    
    // MARK: - Data
    private var folders = Array<String>(repeating: "타이틀", count: 10).enumerated().map {
        $1 + String($0)
    }
    
    private let coreDataStack: CoreDataStack
    private var viewContext: NSManagedObjectContext {
        return coreDataStack.viewContext
    }
    
    // MARK: - Life Cycle
    required init?(coder: NSCoder) {
        fatalError("FoldersViewController not implemented")
    }
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        configureDataSource()
    }
}

// MARK: - Set views
extension FoldersViewController {
    private func setViews() {
        tableView = UITableView(frame: .zero, style: .insetGrouped).then {
            $0.tintColor = .systemPink
            $0.contentInset.bottom = 40
            $0.register(UITableViewCell.self, forCellReuseIdentifier: FoldersViewController.reuseIdentifier)
            $0.delegate = self
        }
        view.addSubview(tableView)
        
        configureHierarchy()
        setNavigationItem()
    }
    
    private func configureHierarchy() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setNavigationItem() {
        addFolderItem = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(addFolderItemTapped)
        )
        
        navigationItem.rightBarButtonItems = [editButtonItem, addFolderItem]
        navigationItem.title = LocalizingHelper.folders
    }
}

// MARK: - Target Action
extension FoldersViewController {
    @objc
    private func addFolderItemTapped() {
        print("폴더추가버튼눌림")
    }
}

// MARK: - Edit Mode
extension FoldersViewController {
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
    }
}

// MARK: - DataSource
extension FoldersViewController {
    class DataSource: UITableViewDiffableDataSource<Section, Int> {
        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            print("moveRowAt=\(sourceIndexPath.item), to=\(destinationIndexPath.item)")
        }
        
        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return (indexPath.item != 0) && (indexPath.item != (snapshot().numberOfItems - 1))
        }
    }
    
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: FoldersViewController.reuseIdentifier, for: indexPath)
            
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.image = UIImage(systemName: "folder")?.withTintColor(.systemPink)
            contentConfiguration.text = self?.folders[itemIdentifier]
            contentConfiguration.secondaryText = "32  >"
            
            cell.contentConfiguration = contentConfiguration
            return cell
        })
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array<Int>(0..<folders.count), toSection: .main)
        
        dataSource.apply(snapshot)
    }
}


// MARK: - UITableViewDelegate
extension FoldersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let blvc = BreadListViewController(coreDataStack: coreDataStack)
        navigationController?.pushViewController(blvc, animated: true)
    }
}

