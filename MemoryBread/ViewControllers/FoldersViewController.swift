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
    private var dataSource: UITableViewDiffableDataSource<Section, NSManagedObjectID>!

    private var noAnimatationForTableView = false
    private var isTableViewCellSwipeActionShowing = false
    
    // MARK: - Alert Action
    private weak var textFieldAlertDoneAction: UIAlertAction?
    
    // MARK: - Buttons
    private var createFolderItem: UIBarButtonItem!
    
    // MARK: - Data
    private let coreDataStack: CoreDataStack
    private var viewContext: NSManagedObjectContext {
        return coreDataStack.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Folder> = {
        let fetchRequest = Folder.fetchRequest()
        
        let pinnedAtTopSort = NSSortDescriptor(key: "pinnedAtTop", ascending: false)
        let pinnedAtBottomSort = NSSortDescriptor(key: "pinnedAtBottom", ascending: true)
        let orderingIndexSort = NSSortDescriptor(key: "index", ascending: true)
        fetchRequest.sortDescriptors = [pinnedAtTopSort, pinnedAtBottomSort, orderingIndexSort]
        fetchRequest.fetchBatchSize = 50
        
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        frc.delegate = self
        return frc
    }()
    
    private let pinnnedAtTopCount = 1
    private let pinnedAtBottomCount = 1
    
    private var rootObjectID: NSManagedObjectID? {
        return fetchedResultsController.fetchedObjects?.first?.objectID
    }
    
    private var trashObjectID: NSManagedObjectID? {
        return fetchedResultsController.fetchedObjects?.last?.objectID
    }
    
    private var folderModel: FolderModel
    
    // MARK: - Life Cycle
    required init?(coder: NSCoder) {
        fatalError("FoldersViewController not implemented")
    }
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        self.folderModel = FolderModel(context: coreDataStack.writeContext)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViews()
        configureDataSource()
        
        try? fetchedResultsController.performFetch()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if isTableViewCellSwipeActionShowing {
            isTableViewCellSwipeActionShowing = false
            tableView.setEditing(false, animated: animated)
        }
        
        tableView.setEditing(editing, animated: animated)
        if !editing {
            let folderObjectIDs = dataSource.snapshot().itemIdentifiers
            folderModel.updateFoldersIndexIfNeeded(of: folderObjectIDs)
            
            if folderModel.isFoldersIndexChanged() {
                folderModel.removeFoldersIndexFlag()
                noAnimatationForTableView = true
            }
        }
    }
}

// MARK: - Set views
extension FoldersViewController {
    private func setViews() {
        tableView = UITableView(frame: .zero, style: .insetGrouped).then {
            $0.tintColor = .systemPink
            $0.contentInset.bottom = 40
            $0.register(FolderListCell.self, forCellReuseIdentifier: FoldersViewController.reuseIdentifier)
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
        createFolderItem = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(createFolderItemTapped)
        )
        
        navigationItem.rightBarButtonItems = [editButtonItem, createFolderItem]
        navigationItem.title = LocalizingHelper.folders
    }
}

// MARK: - Target Action
extension FoldersViewController {
    @objc
    private func createFolderItemTapped() {
        let createFolderAlert = makeTextFieldAlert(
            title: LocalizingHelper.newFolder,
            textInTextField: nil,
            cancelHandler: nil,
            userInputCompletionHandler: {
                [weak self] userInputText in
                guard let folderName = userInputText?.trimmingCharacters(in: [" "]) else {
                    return
                }
                guard let self = self,
                      let topFolderIndex = self
                        .fetchedResultsController
                        .fetchedObjects?[safe: self.pinnnedAtTopCount]?.index else {
                            return
                        }
                
                let newIndex = topFolderIndex - 1
                do {
                    try self.folderModel.createFolderWith(name: folderName, index: newIndex)
                } catch let nserror as NSError {
                    switch nserror.code {
                    case NSManagedObjectConstraintMergeError:
                        self.presentDuplicatedFolderNameAlert()
                    default:
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            }
        )
        
        present(createFolderAlert, animated: true)
    }
    
    private func makeTextFieldAlert(
        title: String?,
        textInTextField: String?,
        cancelHandler: ((UIAlertAction) -> Void)?,
        userInputCompletionHandler: ((String?) -> Void)?
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: LocalizingHelper.enterTheNameOfThisFolder,
            preferredStyle: .alert
        )
        alert.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.text = textInTextField
            textField.placeholder = LocalizingHelper.name
            textField.clearButtonMode = .always
            textField.returnKeyType = .done
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.textDidChange(_:)),
                name: UITextField.textDidChangeNotification,
                object: textField
            )
        }
        
        let cancelAction = UIAlertAction(title: LocalizingHelper.cancel, style: .cancel, handler: cancelHandler)
        let doneAction = UIAlertAction(
            title: LocalizingHelper.save,
            style: .default
        ) { [weak self, weak alert] _ in
            guard let self = self else { return }
            NotificationCenter.default.removeObserver(
                self,
                name: UITextField.textDidChangeNotification,
                object: alert?.textFields?.first
            )
            
            let userInputText = alert?.textFields?.first?.text
            userInputCompletionHandler?(userInputText)
        }
        
        doneAction.isEnabled = !(textInTextField ?? "").isEmpty
        textFieldAlertDoneAction = doneAction
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        return alert
    }
    
    private func presentDuplicatedFolderNameAlert() {
        let errorAlert = BasicAlert.makeConfirmAlert(
            title: LocalizingHelper.nameIsAlreadyInUse,
            message: LocalizingHelper.enterDifferentName
        )
        present(errorAlert, animated: true)
    }
}

// MARK: - DataSource
extension FoldersViewController {
    class DataSource: UITableViewDiffableDataSource<Section, NSManagedObjectID> {
        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            guard sourceIndexPath != destinationIndexPath else { return }

            if let src = itemIdentifier(for: sourceIndexPath),
               let dest = itemIdentifier(for: destinationIndexPath) {
                var snp = snapshot()
                sourceIndexPath.row < destinationIndexPath.row ? snp.moveItem(src, afterItem: dest) : snp.moveItem(src, beforeItem: dest)
                apply(snp, animatingDifferences: false)
            }
        }
        
        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return (indexPath.item != 0) && (indexPath.item != (snapshot().numberOfItems - 1))
        }
    }
    
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, objectID in
            guard let folderObject = try? self?.viewContext.existingObject(with: objectID) as? Folder else {
                fatalError("Managed object should be available")
            }
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FoldersViewController.reuseIdentifier, for: indexPath) as? FolderListCell else {
                fatalError("FolderListCell not available")
            }
            
            let cellItem = FolderListCell.Item(folderObject: folderObject)
            cell.inject(cellItem)
            return cell
        })
    }
}


// MARK: - UITableViewDelegate
extension FoldersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.item > pinnnedAtTopCount - 1)
        && (indexPath.item < (dataSource.snapshot().numberOfItems - pinnedAtBottomCount))
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if (indexPath.item > pinnnedAtTopCount - 1)
            && (indexPath.item < (dataSource.snapshot().numberOfItems - pinnedAtBottomCount)) {
            return .delete
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        if let objectID = dataSource.itemIdentifier(for: indexPath),
           let folderObject = try? viewContext.existingObject(with: objectID) as? Folder,
           let rootObjectID = rootObjectID,
           let trashObjectID = trashObjectID {
            
            if folderObject.pinnedAtBottom {
                let trashVC = TrashViewController(
                    coreDataStack: coreDataStack,
                    rootObjectID: rootObjectID,
                    trashObjectID: trashObjectID
                )
                navigationController?.pushViewController(trashVC, animated: true)
                return
            }
            
            let blvc = BreadListViewController(
                coreDataStack: coreDataStack,
                currentFolderObjectID: folderObject.objectID,
                rootObjectID: rootObjectID,
                trashObjectID: trashObjectID
            )
            navigationController?.pushViewController(blvc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        let itemsCount = dataSource.snapshot().numberOfItems
        
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            let rowInSourceSection = (sourceIndexPath.section > proposedDestinationIndexPath.section) ?
            pinnnedAtTopCount : itemsCount - pinnedAtBottomCount - 1
            return IndexPath(row: rowInSourceSection, section: sourceIndexPath.section)
        } else if proposedDestinationIndexPath.row <= pinnnedAtTopCount - 1 {
            return IndexPath(row: pinnnedAtTopCount, section: sourceIndexPath.section)
        } else if proposedDestinationIndexPath.row >= itemsCount - pinnedAtBottomCount {
            return IndexPath(row: itemsCount - pinnnedAtTopCount - 1, section: sourceIndexPath.section)
        }
        
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.item > pinnnedAtTopCount - 1,
              indexPath.item < dataSource.snapshot().numberOfItems - pinnedAtBottomCount else {
                  return nil
              }
        
        isTableViewCellSwipeActionShowing = true
        
        let folder = fetchedResultsController.object(at: indexPath)
        let deletingAction = makeDeletingTrailingSwipeAction(for: folder)
        let renamingAction = makeRenamingTrailingSwipeAction(for: folder)
        
        let configuration = UISwipeActionsConfiguration(actions: [deletingAction, renamingAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func makeRenamingTrailingSwipeAction(for folder: Folder) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            guard let folderName = folder.name else {
                completionHandler(false)
                return
            }
            
            let textFieldAlert = self.makeTextFieldAlert(
                title: LocalizingHelper.renameFolder,
                textInTextField: folderName,
                cancelHandler: { _ in
                    completionHandler(false)
                },
                userInputCompletionHandler: { userInputText in
                    guard let newFolderName = userInputText?.trimmingCharacters(in: [" "]) else {
                        completionHandler(false)
                        return
                    }
                    
                    do {
                        try self.folderModel.renameFolder(of: folder.objectID, to: newFolderName)
                        completionHandler(true)
                    } catch let nserror as NSError {
                        switch nserror.code {
                        case NSManagedObjectConstraintMergeError:
                            self.presentDuplicatedFolderNameAlert()
                        default:
                            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                        }
                    }                    
                }
            )
            
            self.present(textFieldAlert, animated: true)
        }
        
        action.image = UIImage(systemName: "folder.badge.gearshape")
        action.backgroundColor = .systemBlue
        return action
    }
    
    private func makeDeletingTrailingSwipeAction(for folder: Folder) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: nil) { [weak self, weak folder] _, _, completionHandler in
            guard let self = self,
                  let breadsCount = folder?.breadsCount,
                  let objectID = folder?.objectID else {
                      completionHandler(false)
                      return
                  }
            
            if breadsCount == 0 {
                self.deleteFolder(of: objectID)
                completionHandler(true)
                return
            }
            
            let deletingActionSheet = BasicAlert.makeDestructiveAlertSheet(
                alertTitle: LocalizingHelper.folderAndMemoryBreadWillBeDeleted,
                destructiveTitle: LocalizingHelper.deleteFolder,
                completionHandler: { [weak self] _ in
                    guard let self = self else {
                        completionHandler(false)
                        return
                    }
                    self.deleteFolder(of: objectID)
                    completionHandler(true)
                },
                cancelHandler: { _ in
                    completionHandler(false)
                }
            )
            self.present(deletingActionSheet, animated: true)
        }
        
        action.image = UIImage(systemName: "trash")
        action.backgroundColor = .systemRed
        return action
    }
    
    private func deleteFolder(of folderObjectID: NSManagedObjectID) {
        let trashObjectID = trashObjectID
        coreDataStack.writeAndSaveIfHasChanges { context in
            guard let folder = try? context.existingObject(with: folderObjectID) as? Folder,
                  let trashObjectID = trashObjectID,
                  let trash = try? context.existingObject(with: trashObjectID) as? Folder else {
                return
            }
            
            if let allBreads = folder.breads?.allObjects as? [Bread] {
                allBreads.forEach {
                    $0.move(toTrash: trash)
                }
            }
            
            context.delete(folder)
        }
    }
}

extension FoldersViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        var shouldAnimate = true
        if noAnimatationForTableView {
            noAnimatationForTableView = false
            shouldAnimate = false
        }
        
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>, animatingDifferences: shouldAnimate)
    }
}

// MARK: - TextFieldAlertActionEnabling
extension FoldersViewController: TextFieldAlertActionEnabling {
    var alertAction: UIAlertAction? {
        textFieldAlertDoneAction
    }

    @objc
    private func textDidChange(_ notification: Notification) {
        enableAlertActionByTextCount(notification)
    }
}
