//
//  TrashViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/07.
//

import UIKit
import CoreData
import Combine

final class TrashViewController: UIViewController {
    
    // MARK: - Views
    private lazy var mainView = BreadListView(isCreateButtonAvailable: false, isCopyButtonHidden: true)
    
    private var moresItem = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "ellipsis.circle")
        $0.style = .plain
    }
    
    private let doneItem = UIBarButtonItem().then {
        $0.title = LocalizingHelper.done
        $0.style = .done
    }

    private var feedbackGenerator: UISelectionFeedbackGenerator? = nil
    
    // MARK: - States
    private var isTableViewSwipeActionShowing = false
    
    // MARK: - Models
    private let folderName = LocalizingHelper.trash
    private lazy var trash: Folder = {
        guard let folder = viewContext.object(with: trashObjectID) as? Folder else {
            fatalError("Folder casting error")
        }
        return folder
    }()
    
    private var folderID: UUID? {
        trash.id
    }
    private var trashObjectID: NSManagedObjectID {
        coreDataStack.trashFolderObjectID
    }
    
    private let coreDataStack: CoreDataStack
    private var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Bread> = {
        let fetchRequest = Bread.fetchRequest()

        if let folderID = folderID {
            fetchRequest.predicate = NSPredicate(format: "folder.id = %@", folderID as CVarArg)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "touch", ascending: false)]
        fetchRequest.fetchBatchSize = 50
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        
        return controller
    }()
    
    private var dataSource: BreadListViewController.DataSource!
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
    
    init(
        coreDataStack: CoreDataStack
    ) {
        self.coreDataStack = coreDataStack
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationItem()
        configureDataSource()
        
        mainView.delegate = self
        mainView.tableView.delegate = self
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(setEditMode(_:)))
        gesture.delegate = self
        mainView.tableView.addGestureRecognizer(gesture)
        
        try? fetchedResultsController.performFetch()

        cancellable = NotificationCenter.default
            .publisher(for: .updateViewsForTimeChange)
            .sink() { [weak self] _ in
                guard let self = self else { return }
                var snp = self.dataSource.snapshot()
                snp.reloadSections(snp.sectionIdentifiers)
                self.dataSource.apply(snp)
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
        navigationItem.rightBarButtonItem = editing ? doneItem : moresItem
    }
}

// MARK: - Configure Navigation

extension TrashViewController {
    private func setNavigationItem() {
        navigationItem.title = folderName
        navigationItem.backButtonDisplayMode = .minimal
        
        moresItem.target = self
        moresItem.action = #selector(moresItemTouched)

        doneItem.target = self
        doneItem.action = #selector(doneItemTouched)
        
        navigationItem.rightBarButtonItem = moresItem
    }
}

// MARK: - Target Actions
extension TrashViewController {
    @objc
    private func moresItemTouched() {
        setEditing(true, animated: true)
    }
    
    @objc
    private func doneItemTouched() {
        setEditing(false, animated: true)
    }
    
    @objc
    private func setEditMode(_ sender: UILongPressGestureRecognizer) {
        if .began == sender.state && !isEditing {
            setEditing(true, animated: true)
            feedHaptic()
            let tableView = mainView.tableView
            let location = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: location) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }
}

// MARK: - Configure DataSource
extension TrashViewController {
    private func configureDataSource() {
        dataSource = BreadListViewController.DataSource(tableView: mainView.tableView) { [weak self] tableView, indexPath, objectID in
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
extension TrashViewController: BreadListViewDelegate {
    func deleteButtonTouched(selectedIndexPaths rows: [IndexPath]?) {
        guard let rows = rows else {
            return
        }
        
        let alertTitle: String
        let message: String?
        let destructiveTitle: String
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBread, rows.count)
            message = String(format: LocalizingHelper.deleteNumberOfMemoryBreadTitle, rows.count)
            destructiveTitle = LocalizingHelper.delete
        } else {
            alertTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBreadTitle, rows.count)
            message = nil
            destructiveTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBreadDestructiveTitle, rows.count)
        }
        
        let askingToDeleteAlert = BasicAlert.makeDestructiveAlert(
            alertTitle: alertTitle,
            message: message,
            destructiveTitle: destructiveTitle,
            completionHandler: { [weak self] _ in
                let objectIDs = rows.compactMap {
                    self?.bread(at: $0).objectID
                }
                self?.deleteBreads(of: objectIDs)
                self?.setEditing(false, animated: true)
            })
        present(askingToDeleteAlert, animated: true)
    }
    
    func deleteAllButtonTouched() {
        let numberOfAllBreads = dataSource.snapshot().numberOfItems
        
        let alertTitle: String
        let message: String?
        let destructiveTitle: String
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBread, numberOfAllBreads)
            message = String(format: LocalizingHelper.deleteNumberOfMemoryBreadTitle, numberOfAllBreads)
            destructiveTitle = LocalizingHelper.delete
        } else {
            alertTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBreadTitle, numberOfAllBreads)
            message = nil
            destructiveTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBreadDestructiveTitle, numberOfAllBreads)
        }
        
        let askingToDeleteAlert = BasicAlert.makeDestructiveAlert(
            alertTitle: alertTitle,
            message: message,
            destructiveTitle: destructiveTitle,
            completionHandler: { [weak self] _ in
                if let objectIDs = self?.dataSource.snapshot().itemIdentifiers {
                    self?.deleteBreads(of: objectIDs)
                    self?.setEditing(false, animated: true)
                }
            })
        present(askingToDeleteAlert, animated: true)
    }
    
    func moveButtonTouched(selectedIndexPaths rows: [IndexPath]?) {
        guard let rows = rows,
              rows.count > 0 else {
            return
        }
        
        let selectedObjectIDs = breads(at: rows).map { $0.objectID }
        presentMoveBreadViewControllerWith(
            context: coreDataStack.persistentContainer.newBackgroundContext(),
            targetBreadObjectIDs: selectedObjectIDs
        )
    }
    
    func moveAllButtonTouched() {
        let allObjectIDs = dataSource.snapshot().itemIdentifiers
        presentMoveBreadViewControllerWith(
            context: coreDataStack.persistentContainer.newBackgroundContext(),
            targetBreadObjectIDs: allObjectIDs
        )
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
extension TrashViewController: UITableViewDelegate {
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
        
        
        let breadVC = BreadViewController(context: viewContext, bread: bread(at: indexPath))
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
            
            let alertTitle: String
            let message: String?
            let destructiveTitle: String
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBread, 1)
                message = String(format: LocalizingHelper.deleteNumberOfMemoryBreadTitle, 1)
                destructiveTitle = LocalizingHelper.delete
            } else {
                alertTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBreadTitle, 1)
                message = nil
                destructiveTitle = String(format: LocalizingHelper.deleteNumberOfMemoryBreadDestructiveTitle, 1)
            }
            
            let askingToDeleteAlert = BasicAlert.makeDestructiveAlert(
                alertTitle: alertTitle,
                message: message,
                destructiveTitle: destructiveTitle,
                completionHandler: { [weak self] _ in
                    if let objectID = self?.bread(at: indexPath).objectID {
                        self?.deleteBreads(of: [objectID])
                        completionHandler(true)
                    }
                },
                cancelHandler: { _ in
                    completionHandler(false)
                }
            )
            
            self.present(askingToDeleteAlert, animated: true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    private func deleteBreads(of objectIDs: [NSManagedObjectID]) {
        coreDataStack.writeAndSaveIfHasChanges { context in
            for objectID in objectIDs {
                let object = context.object(with: objectID)
                context.delete(object)
            }
        }
    }
}
// MARK: - NSFetchedResultsControllerDelegate
extension TrashViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>)
        mainView.headerLabelText = String(format: LocalizingHelper.numberOfMemoryBread, snapshot.numberOfItems)
        moresItem.isEnabled = snapshot.numberOfItems != 0
    }
}

// MARK: - MoveBreadViewControllerPresentable
extension TrashViewController: MoveBreadViewControllerPresentable {
    var sourceFolderObjectID: NSManagedObjectID? {
        trashObjectID
    }
    
    var trashFolderObjectID: NSManagedObjectID {
        trashObjectID
    }
}

// MARK: - UIFeedbackGenerator
extension TrashViewController {
    func feedHaptic() {
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        feedbackGenerator?.selectionChanged()
        feedbackGenerator = nil
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TrashViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !isEditing
    }
}
