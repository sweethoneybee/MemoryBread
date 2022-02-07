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

    private var isTableViewReordered = false
    private var isTableViewCellSwipeActionShowing = false
    
    // MARK: - Alert Action
    private weak var folderNameDoneAction: UIAlertAction?
    
    // MARK: - Buttons
    private var addFolderItem: UIBarButtonItem!
    
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
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: viewContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    private let pinnnedAtTopCount = 1
    private let pinnedAtBottomCount = 1
    
    private var rootObjectID: NSManagedObjectID? {
        return dataSource.snapshot().itemIdentifiers.first
    }
    
    private var trashObjectID: NSManagedObjectID? {
        return dataSource.snapshot().itemIdentifiers.last
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
            let snp = dataSource.snapshot()
            snp.itemIdentifiers.enumerated().forEach {
                let newIndex = Int64($0)
                if let folderObject = try? viewContext.existingObject(with: $1) as? Folder,
                   folderObject.index != newIndex {
                    folderObject.index = newIndex
                }
            }

            if viewContext.hasChanges {
                isTableViewReordered = true
                do {
                    try viewContext.save()
                } catch let nserror as NSError {
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
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
        let alert = UIAlertController(title: LocalizingHelper.newFolder, message: LocalizingHelper.enterTheNameOfThisFolder, preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            guard let self = self else { return }
            textField.placeholder = LocalizingHelper.name
            textField.clearButtonMode = .always
            textField.returnKeyType = .done

            NotificationCenter.default.addObserver(self, selector: #selector(self.textDidChange(_:)), name: UITextField.textDidChangeNotification, object: textField)
        }
        
        let cancelAction = UIAlertAction(title: LocalizingHelper.cancel, style: .cancel)
        let doneAction = UIAlertAction(title: LocalizingHelper.save, style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: alert?.textFields?.first)

            guard let folderName = alert?.textFields?.first?.text?.trimmingCharacters(in: [" "]) else {
                return
            }
            guard let topFolderIndex = self.fetchedResultsController.fetchedObjects?[safe: self.pinnnedAtTopCount]?.index else {
                return
            }
            
            let newIndex = topFolderIndex - 1
            let context = self.coreDataStack.writeContext
            context.perform {
                let newFolder = Folder(context: context)
                newFolder.id = UUID()
                newFolder.name = folderName
                newFolder.index = newIndex
                
                do {
                    try context.save()
                } catch let nserror as NSError {
                    switch nserror.code {
                    case NSManagedObjectConstraintMergeError:
                        context.delete(newFolder)
                        DispatchQueue.main.async {
                            let errorAlert = BasicAlert.makeConfirmAlert(title: LocalizingHelper.nameIsAlreadyInUse, message: LocalizingHelper.enterDifferentName)
                            self.present(errorAlert, animated: true)
                        }
                    default:
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            }
        }
        doneAction.isEnabled = false
        folderNameDoneAction = doneAction
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        
        present(alert, animated: true)
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
            
            cell.item = FolderListCell.Item(folderObject: folderObject)
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
        if let objectID = dataSource.itemIdentifier(for: indexPath),
           let folderObject = try? viewContext.existingObject(with: objectID) as? Folder {
            let blvc = BreadListViewController(coreDataStack: coreDataStack)
            blvc.folderName = folderObject.name
            blvc.folderID = folderObject.id
            blvc.folderObjectID = folderObject.objectID
            blvc.rootObjectID = rootObjectID
            blvc.trashObjectID = trashObjectID
            
            navigationController?.pushViewController(blvc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] action, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let folderObject = self.fetchedResultsController.object(at: indexPath)
            if folderObject.breadsCount == 0 {
                self.deleteFolder(of: folderObject.objectID)
                completionHandler(true)
                return
            }
            
            let actionSheet = UIAlertController(title: LocalizingHelper.folderAndMemoryBreadWillBeDeleted, message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: LocalizingHelper.deleteFolder, style: .destructive) { [weak self] _ in
                guard let self = self else {
                    completionHandler(false)
                    return
                }
                self.deleteFolder(of: folderObject.objectID)
                completionHandler(true)
            }
            let cancelAction = UIAlertAction(title: LocalizingHelper.cancel, style: .cancel) { _ in
                completionHandler(false)
            }
            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)
            
            self.present(actionSheet, animated: true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
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
        var shouldAnimate = tableView.numberOfSections != 0
        
        if isTableViewReordered {
            isTableViewReordered = false
            shouldAnimate = false
        }
        
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>, animatingDifferences: shouldAnimate)
    }
}

// MARK: - Notification Action
extension FoldersViewController {
    @objc
    private func textDidChange(_ notification: Notification) {
        guard let textField = notification.object as? UITextField,
              let trimmedText = textField.text?.trimmingCharacters(in: [" "]) else {
            return
        }
        
        if trimmedText.count <= 0 {
            folderNameDoneAction?.isEnabled = false
            return
        }
        folderNameDoneAction?.isEnabled = true
    }
}
