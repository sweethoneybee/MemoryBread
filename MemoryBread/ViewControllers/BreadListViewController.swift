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
    
    private var remoteDriveItem: UIBarButtonItem!
    private var moresItem: UIBarButtonItem!
    private var doneItem: UIBarButtonItem!
    
    private var bottomToolbar: BottomToolbar!
    private var deleteButton: UIButton!
    private var deleteAllButton: UIButton!
    
    private var normalRightBarButtonItems: [UIBarButtonItem] {
//        return [moresItem, remoteDriveItem]
        return [moresItem]
    }
    
    private var editRightBarButtonItems: [UIBarButtonItem] {
        return [doneItem]
    }
    
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
        
        tableView = UITableView(frame: .zero, style: .insetGrouped).then {
            $0.allowsMultipleSelectionDuringEditing = true
            $0.tintColor = .systemPink
            $0.contentInset.bottom = 40
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BreadListViewController.reuseIdentifier)
        view.addSubview(tableView)

        headerLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 14, weight: .light)
            $0.textAlignment = .center
            $0.frame.size.height = 30
            tableView.tableHeaderView = $0
        }
        
        addBreadButton = UIButton().then {
            $0.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            $0.tintColor = .systemPink
            $0.addTarget(self, action: #selector(addBreadButtonTouched), for: .touchUpInside)
        }
        view.addSubview(addBreadButton)
        
        bottomToolbar = BottomToolbar(frame: .init(x: 0, y: 0, width: 200, height: 100)).then {
            $0.isHidden = true
        }
        view.addSubview(bottomToolbar)
        
        deleteButton = UIButton(type: .system).then {
            $0.setTitle(LocalizingHelper.delete, for: .normal)
            $0.tintColor = .systemPink
            $0.addTarget(self, action: #selector(deleteButtonTouched), for: .touchUpInside)
            bottomToolbar.addArrangedSubview($0, to: .right)
        }
        
        deleteAllButton = UIButton(type: .system).then {
            $0.setTitle(LocalizingHelper.deleteAll, for: .normal)
            $0.tintColor = .systemPink
            $0.addTarget(self, action: #selector(deleteAllButtonTouched), for: .touchUpInside)
            bottomToolbar.addArrangedSubview($0, to: .right)
        }
        
        configureHierarchy()
        setRightButtomItems()
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
        
        bottomToolbar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }
    
    private func setRightButtomItems() {
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
    func addBreadButtonTouched() {
        guard isAdding == false else {
            return
        }
        
        isAdding = true
        let writeContext = coreDataStack.writeContext
        writeContext.perform {
            let newBread = Bread.makeBasicBread(context: writeContext)
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
    
    @objc
    func remoteDriveItemTouched() {
        let rdaVC = RemoteDriveAuthViewController(context: coreDataStack.writeContext)
        let nvc = UINavigationController(rootViewController: rdaVC)
        present(nvc, animated: true)
    }
    
    @objc
    func moresItemTouched() {
        setTableViewEditing(true, animated: true)
    }
    
    @objc
    func doneItemTouched() {
        setTableViewEditing(false, animated: true)
    }
    
    @objc
    func deleteButtonTouched() {
        if let rows = tableView.indexPathsForSelectedRows {
            let alertSheet = BasicAlert.makeDestructiveAlertSheet(alertTitle: String(format: LocalizingHelper.selectedNumberOfItems, rows.count), destructiveTitle: LocalizingHelper.deleteSelectedMemoryBread) { [weak self] _ in
                let objectIDs = rows.compactMap {
                    self?.fetchedResultsController.object(at: $0).objectID
                }
                self?.coreDataStack.deleteAndSaveObjects(of: objectIDs)
                self?.setTableViewEditing(false, animated: true)
            }
            present(alertSheet, animated: true)
        }
    }
    
    @objc
    func deleteAllButtonTouched() {
        let actionSheet = BasicAlert.makeDestructiveAlertSheet(destructiveTitle: LocalizingHelper.deleteAll) { [weak self] _ in
            if let objectIDs = self?.fetchedResultsController.fetchedObjects?.map({ $0.objectID }) {
                self?.coreDataStack.deleteAndSaveObjects(of: objectIDs)
                self?.setTableViewEditing(false, animated: true)
            }
        }
        present(actionSheet, animated: true)
    }
}

// MARK: - Update Views
extension BreadListViewController {
    private func setTableViewEditing(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
        updateViewsInEditMode(withCount: 0)
        if animated {
            let animation = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
                self.updateUI(whenEditing: editing)
            }
            animation.startAnimation()
        } else {
            updateUI(whenEditing: editing)
        }
    }
    
    private func updateUI(whenEditing editing: Bool) {
        bottomToolbar.isHidden = !editing
        addBreadButton.isHidden = editing
        navigationItem.hidesBackButton = editing
        
        if editing {
            bottomToolbar.layer.opacity = 1
            addBreadButton.layer.opacity = 0
            navigationItem.rightBarButtonItems = editRightBarButtonItems
        } else {
            bottomToolbar.layer.opacity = 0
            addBreadButton.layer.opacity = 1
            navigationItem.rightBarButtonItems = normalRightBarButtonItems
        }
    }
    
    private func updateViewsInEditMode(withCount numberOfSelectedRows: Int) {
        let hasSelectedRows = (numberOfSelectedRows != 0)
        deleteButton.isHidden = !hasSelectedRows
        deleteAllButton.isHidden = hasSelectedRows
        navigationItem.title = hasSelectedRows ? String(format: LocalizingHelper.selectedNumberOfItems, numberOfSelectedRows) : LocalizingHelper.appTitle
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
        if tableView.isEditing {
            updateViewsInEditMode(withCount: tableView.indexPathsForSelectedRows?.count ?? 0)
            return
        }
        let breadVC = BreadViewController(context: viewContext, bread: fetchedResultsController.object(at: indexPath))
        navigationController?.pushViewController(breadVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateViewsInEditMode(withCount: tableView.indexPathsForSelectedRows?.count ?? 0)
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let willBeDeletedObjectID = self.fetchedResultsController.object(at: indexPath).objectID
            self.coreDataStack.deleteAndSaveObjects(of: [willBeDeletedObjectID])
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

