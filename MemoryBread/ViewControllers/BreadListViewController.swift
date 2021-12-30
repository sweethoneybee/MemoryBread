//
//  BreadListViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
//  'ImplementingModernCollectionViews' sample code from Apple.
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
    private let coreDataStack: CoreDataStack
    private let viewContext: NSManagedObjectContext
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "touch", ascending: false)]
        fetchRequest.fetchBatchSize = 50
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.viewContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        controller.delegate = self
        
        return controller
    }()

    // MARK: - Life Cycle
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        self.viewContext = coreDataStack.viewContext
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        configureDataSource()
        tableView.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isBeingPresented || isMovingToParent {
            try? fetchedResultsController.performFetch()
        }
    }
}

// MARK: - Configure Views
extension BreadListViewController {
    private func setViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "app_title".localized
        navigationItem.backButtonDisplayMode = .minimal
        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BreadListViewController.reuseIdentifier)
        view.addSubview(tableView)

        headerLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 14, weight: .light)
            $0.textAlignment = .center
            $0.textColor = .black
            $0.frame.size.height = 30
            tableView.tableHeaderView = $0
        }
        
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
        let bread = Bread.makeBasicBread(context: viewContext)
        do {
            try viewContext.save()
        } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        let breadViewController = BreadViewController(context: viewContext, bread: bread)
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
            guard let object = try? self?.viewContext.existingObject(with: objectID) as? Bread else {
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
        let breadVC = BreadViewController(context: viewContext, bread: fetchedResultsController.object(at: indexPath))
        navigationController?.pushViewController(breadVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let willBeDeletedObjectID = self.fetchedResultsController.object(at: indexPath).objectID
            self.coreDataStack.deleteObject(with: willBeDeletedObjectID)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension BreadListViewController: NSFetchedResultsControllerDelegate {
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

