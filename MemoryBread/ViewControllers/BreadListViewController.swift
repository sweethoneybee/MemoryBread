//
//  BreadListViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
//  'ImplementingModernCollectionViews' sample code from Apple.
//
//  DiffableDataSource with Core Data codes are mainly refer to
//  'https://www.avanderlee.com/swift/diffable-data-sources-core-data/'
// 

import UIKit
import SnapKit
import CoreData

final class BreadListViewController: UIViewController {
    static let reuseIdentifier = "reuse-identifier-bread-list-view"

    // MARK: - Views
    private var tableView: UITableView!
    private var headerLabel: UILabel!
    private var addBreadButton: UIButton!
    
    // MARK: - States
    private var diffableDataSource: UITableViewDiffableDataSource<Int, NSManagedObjectID>!
    private var isAdding = false
    
    // MARK: - Models
    private let viewContext = AppDelegate.viewContext
    private let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType).then {
        $0.parent = AppDelegate.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "touch", ascending: false)]
        fetchRequest.fetchBatchSize = 50
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.managedObjectContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        controller.delegate = self
        
        return controller
    }()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        configureDataSource()
        
        tableView.delegate = self
        
        try? fetchedResultsController.performFetch()
        
        NotificationCenter.default.addObserver(self, selector: #selector(childContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: managedObjectContext)
    }
    
    // MARK: - Notification Handlers
    @objc
    private func childContextDidSave(_ notification: Notification) {
        try? viewContext.save()
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BreadListViewController.reuseIdentifier)
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
        let remoteDriveItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(remoteDriveItemTouched))
        navigationItem.rightBarButtonItem = remoteDriveItem
    }
    
    @objc
    func addBreadButtonTouched() {
        guard isAdding == false else {
            return
        }
        
        isAdding = true
        let bread = Bread.makeBasicBread(context: self.managedObjectContext)
        try? managedObjectContext.save()
        let breadViewController = BreadViewController(context: managedObjectContext, bread: bread)
        navigationController?.pushViewController(breadViewController, animated: true)
        isAdding = false
    }
    
    @objc
    func remoteDriveItemTouched() {
        let rdaVC = RemoteDriveAuthViewController()
        let nvc = UINavigationController(rootViewController: rdaVC)
        present(nvc, animated: true)
    }
}

// MARK: - DataSource
extension BreadListViewController {
    class DataSource: UITableViewDiffableDataSource<Int, NSManagedObjectID> {
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
    }
    
    private func configureDataSource() {
        let titleAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
        let dateAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .ultraLight)]
        let bodyAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .light)]
        
        let dateHelper = DateHelper()
        diffableDataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, objectID in
            guard let object = try? self?.managedObjectContext.existingObject(with: objectID) as? Bread else {
                fatalError("Managed object should be available")
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: BreadListViewController.reuseIdentifier, for: indexPath)
            
            var content = cell.defaultContentConfiguration()
            let titleAttributedString = NSAttributedString(string: object.title ?? "", attributes: titleAttribute)
            content.attributedText = titleAttributedString
            content.textProperties.numberOfLines = 1
            
            let dateString = dateHelper.string(from: object.touch ?? Date())
            let secondaryAttributedString = NSMutableAttributedString(string: dateString + " ", attributes: dateAttribute)
            secondaryAttributedString.append(NSAttributedString(string: String((object.content ?? "").prefix(200)), attributes: bodyAttribute))
            
            content.secondaryAttributedText = secondaryAttributedString
            content.secondaryTextProperties.numberOfLines = 1
            
            cell.contentConfiguration = content
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension BreadListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let breadViewController = BreadViewController(context: managedObjectContext, bread: fetchedResultsController.object(at: indexPath))
        navigationController?.pushViewController(breadViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let object = self.fetchedResultsController.object(at: indexPath)
            self.managedObjectContext.delete(object)
            try? self.managedObjectContext.save()
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension BreadListViewController: NSFetchedResultsControllerDelegate {
    // codes refer to 'https://www.avanderlee.com/swift/diffable-data-sources-core-data/'
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = tableView.dataSource as? UITableViewDiffableDataSource<Int, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }

        let shouldAnimate = tableView.numberOfSections != 0
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
        headerLabel.text = String(format: LocalizingHelper.numberOfMemoryBread, snapshot.numberOfItems)
    }
}

