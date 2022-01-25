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

    // MARK: - Alert Action
    private weak var folderNameDoneAction: UIAlertAction?
    
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
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Folder> = {
        let fetchRequest = Folder.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "orderingNumber", ascending: false)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: viewContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
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
            guard let lastOrderingNumber = self.fetchedResultsController.fetchedObjects?[safe: 1]?.orderingNumber else {
                return
            }
            
            let context = self.coreDataStack.writeContext
            context.perform {
                let newFolder = Folder(context: context)
                newFolder.id = UUID()
                newFolder.name = folderName
                newFolder.orderingNumber = lastOrderingNumber + 1
                
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

// MARK: - Edit Mode
extension FoldersViewController {
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
    }
}

// MARK: - DataSource
extension FoldersViewController {
    class DataSource: UITableViewDiffableDataSource<Section, NSManagedObjectID> {
        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            print("moveRowAt=\(sourceIndexPath.item), to=\(destinationIndexPath.item)")
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
            let cell = tableView.dequeueReusableCell(withIdentifier: FoldersViewController.reuseIdentifier, for: indexPath)
            
            var contentConfiguration = UIListContentConfiguration.valueCell()
            
            let imageName: String
            if folderObject.orderingNumber == 0 {
                imageName = "trash"
            } else {
                imageName = "folder"
            }
            contentConfiguration.image = UIImage(systemName: imageName)?.withTintColor(.systemPink)
            contentConfiguration.text = folderObject.name
            contentConfiguration.secondaryText = "\(folderObject.breads?.count ?? -1)  >"
            
            cell.contentConfiguration = contentConfiguration
            return cell
        })
    }
}


// MARK: - UITableViewDelegate
extension FoldersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.item != 0)
        && (indexPath.item != (dataSource.snapshot().numberOfItems - 1))
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if (indexPath.item != 0)
            && (indexPath.item != (dataSource.snapshot().numberOfItems - 1)) {
            return .delete
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = fetchedResultsController.object(at: indexPath)
        let blvc = BreadListViewController(coreDataStack: coreDataStack, folderName: folder.name)
        navigationController?.pushViewController(blvc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension FoldersViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let shouldAnimate = tableView.numberOfSections != 0
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
