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
import Combine

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
    private let coreDataStack: CoreDataStack
    private let currentFolderObjectID: NSManagedObjectID
    private let isAllBreadsFolder: Bool
    
    private lazy var folderObject: Folder = {
        guard let folder = viewContext.object(with: currentFolderObjectID) as? Folder else {
            fatalError("Folder casting error")
        }
        return folder
    }()
    
    private var folderName: String {
        folderObject.localizedName
    }
    
    private var folderID: UUID? {
        folderObject.id
    }
    
    private var showFolder: Bool {
        folderObject.pinnedAtTop && folderObject.isSystemFolder
    }
    
    private var defaultFolderObjectID: NSManagedObjectID {
        coreDataStack.defaultFolderObjectID
    }
    private var trashObjectID: NSManagedObjectID {
        coreDataStack.trashFolderObjectID
    }
    
    private var folderObjectIDForCreating: NSManagedObjectID {
        isAllBreadsFolder ? defaultFolderObjectID : currentFolderObjectID
    }
    
    private var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()
        if let folderID = folderID {
            fetchRequest.predicate = isAllBreadsFolder ? NSPredicate(format: "folder.pinnedAtBottom = NO") : NSPredicate(format: "folder.id = %@", folderID as CVarArg)
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

    private var diffableDataSource: BreadListViewController.DataSource!
    private var cancellable: Cancellable?

    // MARK: - Life Cycle
    override func loadView() {
        self.view = mainView
        self.view.backgroundColor = .systemBackground
        self.view.tintColor = .systemPink
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(coreDataStack: CoreDataStack, currentFolderObjectID: NSManagedObjectID, isAllBreadsFolder: Bool) {
        self.coreDataStack = coreDataStack
        self.currentFolderObjectID = currentFolderObjectID
        self.isAllBreadsFolder = isAllBreadsFolder
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationItem()
        configureDataSource()
        
        mainView.delegate = self
        mainView.tableView.delegate = self
        
        try? fetchedResultsController.performFetch()
        
        cancellable = NotificationCenter.default
            .publisher(for: .updateViewsForTimeChange)
            .sink() { [weak self] _ in
                guard let self = self else { return }
                var snp = self.diffableDataSource.snapshot()
                snp.reloadSections(snp.sectionIdentifiers)
                self.diffableDataSource.apply(snp)
            }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if isTableViewSwipeActionShowing {
            isTableViewSwipeActionShowing = false
            mainView.setEditing(false, animated: animated)
        }
        
        mainView.setEditing(editing, animated: animated)
        mainView.updateUI(for: .init(isEditing: editing, numberOfSelectedRows: 0))
        
        navigationItem.title = folderName
        navigationItem.hidesBackButton = editing
        navigationItem.rightBarButtonItems = editing ? editingRightBarButtonItems : normalRightBarButtonItems
    }
}

// MARK: - Configure Navigation
extension BreadListViewController {
    
    private func setNavigationItem() {
        navigationItem.title = folderName
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
        let rdaVC = RemoteDriveAuthViewController(
            context: coreDataStack.writeContext,
            folderObjectID: folderObjectIDForCreating
        )
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
    class DataSource: UITableViewDiffableDataSource<String, NSManagedObjectID> {
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
            
            cell.configure(using: bread, showFolder: self?.showFolder ?? false)
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
            guard let folder = try? writeContext.existingObject(with: self.folderObjectIDForCreating) as? Folder else {
                self.isAdding = false
                return
            }
            let newBread = Bread(
                context: writeContext,
                title: LocalizingHelper.freshBread,
                content: "",
                selectedFilters: [],
                folder: folder
            )
            
            writeContext.saveContextAndParentIfNeeded()
            
            DispatchQueue.main.async { [weak self] in
                if let self = self,
                   let bread = try? self.viewContext.existingObject(with: newBread.objectID) as? Bread {
                    
                    let childContext = self.coreDataStack.makeChildMainQueueContext()
                    if let childBread = childContext.object(with: bread.objectID) as? Bread {
                        let breadVC = BreadViewController(context: childContext, bread: childBread)
                        self.navigationController?.pushViewController(breadVC, animated: true)
                    }
                    self.isAdding = false
                }
            }
        }
    }
    
    func deleteButtonTouched(selectedIndexPaths rows: [IndexPath]?) {
        guard let rows = rows,
              rows.count > 0 else {
            return
        }

        let selectedObjectIDs = breads(at: rows).map { $0.objectID }
        moveToTrash(of: selectedObjectIDs)
        setEditing(false, animated: true)
    }
    
    func deleteAllButtonTouched() {
        let askingToDeleteAllSheet = BasicAlert.makeDestructiveAlertSheet(
            alertTitle: nil,
            destructiveTitle: LocalizingHelper.deleteAll,
            completionHandler: { [weak self] _ in
                if let objectIDs = self?.diffableDataSource.snapshot().itemIdentifiers {
                    self?.moveToTrash(of: objectIDs)
                    self?.setEditing(false, animated: true)
                }
            }
        )
        present(askingToDeleteAllSheet, animated: true)
    }
    
    private func moveToTrash(of objectIDs: [NSManagedObjectID]) {
        coreDataStack.writeAndSaveIfHasChanges { context in
            guard let trash = try? context.existingObject(with: self.trashObjectID) as? Folder else {
                return
            }
            
            objectIDs.forEach {
                if let bread = try? context.existingObject(with: $0) as? Bread {
                    bread.move(to: trash)
                }
            }
        }
    }
    
    func moveButtonTouched(selectedIndexPaths rows: [IndexPath]?) {
        guard let rows = rows,
              rows.count > 0 else {
            return
        }
        
        let selectedObjectIDs = breads(at: rows).map { $0.objectID }
        let childContext = coreDataStack.makeChildConcurrencyQueueContext()
        presentMoveBreadViewControllerWith(context: childContext, targetBreadObjectIDs: selectedObjectIDs)
    }
    
    func moveAllButtonTouched() {
        let allObjectIDs = diffableDataSource.snapshot().itemIdentifiers
        let childContext = coreDataStack.makeChildConcurrencyQueueContext()
        presentMoveBreadViewControllerWith(context: childContext, targetBreadObjectIDs: allObjectIDs)
    }
    
    private func bread(at indexPath: IndexPath) -> Bread {
        return fetchedResultsController.object(at: indexPath)
    }
    
    private func breads(at indexPaths: [IndexPath]) -> [Bread] {
        return indexPaths.map {
            fetchedResultsController.object(at: $0)
        }
    }
}

// MARK: - UITableViewDelegate
extension BreadListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (showFolder) ? CGFloat(75) : CGFloat(60)
    }

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
        
        let childContext = coreDataStack.makeChildMainQueueContext()
        let selectedObjectID = bread(at: indexPath).objectID
        if let childBread = childContext.object(with: selectedObjectID) as? Bread {
            let breadVC = BreadViewController(context: childContext, bread: childBread)
            navigationController?.pushViewController(breadVC, animated: true)            
        }
        
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

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        isTableViewSwipeActionShowing = true
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] action, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let objectID = self.bread(at: indexPath).objectID
            self.moveToTrash(of: [objectID])
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
        diffableDataSource.apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>)
        mainView.headerLabelText = String(format: LocalizingHelper.numberOfMemoryBread, snapshot.numberOfItems)
        moresItem.isEnabled = snapshot.numberOfItems != 0
    }
}

// MARK: - MoveBreadViewControllerPresentable
extension BreadListViewController: MoveBreadViewControllerPresentable {
    var sourceFolderObjectID: NSManagedObjectID? {
        isAllBreadsFolder ? nil : currentFolderObjectID
    }
    
    var trashFolderObjectID: NSManagedObjectID {
        trashObjectID
    }
}
