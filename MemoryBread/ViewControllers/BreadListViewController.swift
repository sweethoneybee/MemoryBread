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
    
    private var feedbackGenerator: UISelectionFeedbackGenerator? = nil
    
    // MARK: - States
    private var isAdding = false
    private var isTableViewSwipeActionShowing = false
    
    // MARK: - Models
    private var subscriptions = Set<AnyCancellable>()
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
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(setEditMode(_:)))
        gestureRecognizer.delegate = self
        mainView.tableView.addGestureRecognizer(gestureRecognizer)
        
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
}

// MARK: - Target Actions
extension BreadListViewController {
    @objc
    func remoteDriveItemTouched() {
        let rdaVC = RemoteDriveAuthViewController(
            context: coreDataStack.persistentContainer.newBackgroundContext(),
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
        coreDataStack.writeAndSaveIfHasChanges { context in
            guard let folder = try? context.existingObject(with: self.folderObjectIDForCreating) as? Folder else {
                self.isAdding = false
                return
            }
            let newBread = Bread(
                context: context,
                title: LocalizingHelper.freshBread,
                content: "",
                selectedFilters: [],
                folder: folder
            )
            
            context.saveIfNeeded()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                if let bread = try? self.viewContext.existingObject(with: newBread.objectID) as? Bread {
                    let breadVC = BreadViewController(context: self.viewContext, bread: bread)
                    self.navigationController?.pushViewController(breadVC, animated: true)
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
        let message: String?
        let destructiveTitle: String?
        if UIDevice.current.userInterfaceIdiom == .pad {
            message = LocalizingHelper.deleteAllMemoryBreadMessage
            destructiveTitle = LocalizingHelper.delete
        } else {
            message = nil
            destructiveTitle = LocalizingHelper.deleteAll
        }
        
        let askingToDeleteAlert = BasicAlert.makeDestructiveAlert(
            alertTitle: nil,
            message: message,
            destructiveTitle: destructiveTitle,
            completionHandler: { [weak self] _ in
                if let objectIDs = self?.diffableDataSource.snapshot().itemIdentifiers {
                    self?.moveToTrash(of: objectIDs)
                    self?.setEditing(false, animated: true)
                }
            }
        )
        present(askingToDeleteAlert, animated: true)
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
        presentMoveBreadViewControllerWith(
            context: coreDataStack.persistentContainer.newBackgroundContext(),
            targetBreadObjectIDs: selectedObjectIDs
        )
    }
    
    func moveAllButtonTouched() {
        let allObjectIDs = diffableDataSource.snapshot().itemIdentifiers
        presentMoveBreadViewControllerWith(
            context: coreDataStack.persistentContainer.newBackgroundContext(),
            targetBreadObjectIDs: allObjectIDs
        )
    }
    
    func copyButtonTouched(selectedIndexPaths rows: [IndexPath]?) {
        guard let rows = rows,
              !rows.isEmpty else {
            return
        }
        
        askUser(
            for: LocalizingHelper.copyMemoryBreads,
            message: String(format: LocalizingHelper.copyNumberOfMemoryBreads, rows.count)
        )
        .map{ self.breads(at: rows) }
        .flatMap(copy)
        .receive(on: DispatchQueue.main)
        .sink { result in
            switch result {
            case .finished:
                self.setEditing(false, animated: true)
            case .failure(let copyError):
                switch copyError {
                case .cancel:
                    break
                case .copyFail(let errorCode):
                    let errorAlert = BasicAlert.makeErrorAlert(
                        message: String(format: LocalizingHelper.failedToCopy, errorCode)
                    )
                    self.present(errorAlert, animated: true)
                }
            }
        } receiveValue: { _ in }
        .store(in: &subscriptions)
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

// MARK: - Bread Copy
extension BreadListViewController {
    enum CopyError: Error {
        typealias errorCode = Int
        case cancel
        case copyFail(errorCode)
    }
    
    private func askUser(for title: String, message: String) -> AnyPublisher<Void, CopyError> {
        Future<Void, CopyError> { promise in
            let alert = BasicAlert.makeCancelAndConfirmAlert(
                title: title,
                message: message,
                cancelHandler: { _ in promise(.failure(.cancel)) },
                completionHandler: { _ in promise(.success(())) }
            )
            self.present(alert, animated: true)
        }
        .eraseToAnyPublisher()
    }
    
    private func copy(_ breads: [Bread]) -> AnyPublisher<Void, CopyError> {
        return Future<Void, CopyError> { promise in
            let breadIds = breads.map{ $0.objectID }
            self.coreDataStack.persistentContainer.performBackgroundTask { context in
                let originalBreads = breadIds.compactMap {
                    return (try? context.existingObject(with:$0)) as? Bread
                }
                originalBreads.forEach {
                    _ = Bread(
                        context: context,
                        title: $0.title,
                        content: $0.content,
                        filterIndexes: $0.filterIndexes,
                        selectedFilters: [],
                        folder: $0.folder
                    )
                }
                
                do {
                    try context.save()
                    promise(.success(()))
                } catch let nserror as NSError {
                    promise(.failure(.copyFail(nserror.code)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - UIFeedbackGenerator
extension BreadListViewController {
    func feedHaptic() {
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        feedbackGenerator?.selectionChanged()
        feedbackGenerator = nil
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BreadListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !isEditing
    }
}
