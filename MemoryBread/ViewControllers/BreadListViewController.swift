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

    // MARK: - Views
    private lazy var mainView = BreadListView()
    
    private var remoteDriveItem: UIBarButtonItem!
    private var moresItem: UIBarButtonItem!
    private var doneItem: UIBarButtonItem!
    
    private var normalRightBarButtonItems: [UIBarButtonItem] {
        return [moresItem, remoteDriveItem]
    }
    
    private var editingRightBarButtonItems: [UIBarButtonItem] {
        return [doneItem]
    }
    
    // MARK: - States
    private var isAdding = false
    private var isTableViewSwipeActionShowing = false
    
    // MARK: - Models
    var folderName: String?
    var folderID: UUID?
    var folderObjectID: NSManagedObjectID?
    var rootObjectID: NSManagedObjectID?
    var trashObjectID: NSManagedObjectID?
    
    private let coreDataStack: CoreDataStack
    private var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()
        if let folderID = folderID {
            fetchRequest.predicate = NSPredicate(format: "ANY folders.id = %@", folderID as CVarArg)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "touch", ascending: false)]
        fetchRequest.fetchBatchSize = 50
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        
        return controller
    }()

    private var diffableDataSource: UITableViewDiffableDataSource<Int, NSManagedObjectID>!

    // MARK: - Life Cycle
    override func loadView() {
        self.view = mainView
        self.view.backgroundColor = .systemBackground
        self.view.tintColor = .systemPink
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationItem()
        configureDataSource()
        
        mainView.delegate = self
        mainView.tableView.delegate = self
        
        try? fetchedResultsController.performFetch()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if isTableViewSwipeActionShowing {
            isTableViewSwipeActionShowing = false
            mainView.tableView.setEditing(false, animated: animated)
        }
        
        mainView.tableView.setEditing(editing, animated: animated)
        mainView.updateUI(for: .init(isEditing: editing, numberOfSelectedRows: 0))
        
        navigationItem.title = folderName
        navigationItem.hidesBackButton = editing
        navigationItem.rightBarButtonItems = editing ? editingRightBarButtonItems : normalRightBarButtonItems
    }
}

// MARK: - Configure Navigation
extension BreadListViewController {
    
    private func setNavigationItem() {
        navigationItem.title = folderName ?? LocalizingHelper.appTitle
        navigationItem.backButtonDisplayMode = .minimal
        
        remoteDriveItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(remoteDriveItemTouched)
        )
        
        moresItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(moresItemTouched)
        )
        
        doneItem = UIBarButtonItem(
            title: LocalizingHelper.done,
            style: .done,
            target: self,
            action: #selector(doneItemTouched)
        )
        
        navigationItem.rightBarButtonItems = normalRightBarButtonItems
    }
    
    // MARK: - UIButton Target Actions
    @objc
    func remoteDriveItemTouched() {
        let rdaVC = RemoteDriveAuthViewController(context: coreDataStack.writeContext)
        rdaVC.folderObjectID = folderObjectID
        rdaVC.rootObjectID = rootObjectID
        let nvc = UINavigationController(rootViewController: rdaVC)
        present(nvc, animated: true)
    }
    
    @objc
    func moresItemTouched() {
        setEditing(true, animated: true)
    }
    
    @objc
    func doneItemTouched() {
        setEditing(false, animated: true)
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
        diffableDataSource = DataSource(tableView: mainView.tableView) { [weak self] tableView, indexPath, objectID in
            guard let bread = try? self?.viewContext.existingObject(with: objectID) as? Bread else {
                fatalError("Managed object should be available")
            }
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BreadListCell.reuseIdentifier, for: indexPath) as? BreadListCell else {
                fatalError("Cell reuse identifier should be available")
            }
            
            cell.configure(using: bread)
            return cell
        }
    }
}

// MARK: - BreadListViewDelegate
extension BreadListViewController: BreadListViewDelegate {
    func createBreadButtonTouched() {
        guard isAdding == false else {
            return
        }
        
        isAdding = true
        let writeContext = coreDataStack.writeContext
        writeContext.perform {
            let newBread = Bread.makeBasicBread(context: writeContext)
            if let rootObjectID = self.rootObjectID,
               let root = try? writeContext.existingObject(with: rootObjectID) as? Folder,
               let folderObjectID = self.folderObjectID,
               let folder = try? writeContext.existingObject(with: folderObjectID) as? Folder {
                newBread.addToFolders(root)
                newBread.addToFolders(folder)
            }
            
            do {
                try writeContext.save()
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            DispatchQueue.main.async { [weak self] in
                if let self = self,
                   let bread = try? self.viewContext.existingObject(with: newBread.objectID) as? Bread {
                    let breadVC = BreadViewController(context: self.viewContext, bread: bread)
                    self.navigationController?.pushViewController(breadVC, animated: true)
                    self.isAdding = false
                }
            }
        }
    }
    
    func deleteButtonTouched(selectedIndexPaths rows: [IndexPath]?) {
        guard let rows = rows else {
            return
        }
        
        let alertSheet = BasicAlert.makeDestructiveAlertSheet(
            alertTitle: String(format: LocalizingHelper.selectedNumberOfItems, rows.count),
            destructiveTitle: LocalizingHelper.deleteSelectedMemoryBread,
            completionHandler: { [weak self] _ in
                let objectIDs = rows.compactMap {
                    self?.fetchedResultsController.object(at:$0).objectID
                }
                self?.moveToTrash(of: objectIDs)
                self?.setEditing(false, animated: true)
            }
        )
        present(alertSheet, animated: true)
    }
    
    func deleteAllButtonTouched() {
        let actionSheet = BasicAlert.makeDestructiveAlertSheet(destructiveTitle: LocalizingHelper.deleteAll) { [weak self] _ in
            if let objectIDs = self?.fetchedResultsController.fetchedObjects?.map({ $0.objectID }) {
                self?.moveToTrash(of: objectIDs)
                self?.setEditing(false, animated: true)
            }
        }
        present(actionSheet, animated: true)
    }
    
    private func moveToTrash(of objectIDs: [NSManagedObjectID]) {
        guard let trashObjectID = trashObjectID else {
            return
        }
        
        coreDataStack.writeAndSaveIfHasChanges { context in
            guard let trash = try? context.existingObject(with: trashObjectID) as? Folder else {
                return
            }
            
            objectIDs.forEach {
                if let bread = try? context.existingObject(with: $0) as? Bread {
                    bread.move(toTrash: trash)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension BreadListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let indexPaths = tableView.indexPathsForSelectedRows
            mainView.updateUI(for: .init(
                isEditing: true,
                numberOfSelectedRows: indexPaths?.count ?? 0
            ))
            navigationItem.title = (indexPaths != nil) ? String(format: LocalizingHelper.selectedNumberOfItems, indexPaths!.count) : folderName
            return
        }
        
        let breadVC = BreadViewController(context: viewContext, bread: fetchedResultsController.object(at: indexPath))
        navigationController?.pushViewController(breadVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let indexPaths = tableView.indexPathsForSelectedRows
            mainView.updateUI(for: .init(
                isEditing: true,
                numberOfSelectedRows: indexPaths?.count ?? 0
            ))
            navigationItem.title = (indexPaths != nil) ? String(format: LocalizingHelper.selectedNumberOfItems, indexPaths!.count) : folderName
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        isTableViewSwipeActionShowing = true
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] action, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let objectIDAtIndexPath = self.fetchedResultsController.object(at: indexPath).objectID
            self.moveToTrash(of: [objectIDAtIndexPath])
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
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = mainView.tableView.dataSource as? UITableViewDiffableDataSource<Int, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        let shouldAnimate = mainView.tableView.numberOfSections != 0
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
        mainView.tableViewHeaderLabel.text = String(format: LocalizingHelper.numberOfMemoryBread, snapshot.numberOfItems)
    }
}

