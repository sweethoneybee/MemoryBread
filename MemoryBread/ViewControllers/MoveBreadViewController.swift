//
//  MoveBreadViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/11.
//

import UIKit
import CoreData
import Combine

final class MoveBreadViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.register(MoveFolderListCell.self, forCellReuseIdentifier: MoveFolderListCell.cellReuseIdentifier)
    }
    
    private let selectedBreadsView = SubTitleView(frame: .zero)
    private let cancelBarButtonItem = UIBarButtonItem(
        title: LocalizingHelper.cancel,
        style: .plain,
        target: nil,
        action: nil
    ).then {
        $0.tintColor = .systemPink
    }
    private weak var askingFolderNameDoneAction: UIAlertAction?
    
    typealias FolderItem = MoveBreadModel.Item
    typealias DoneHandler = (() -> Void)

    private let model: MoveBreadModel
    private var dataSource: UITableViewDiffableDataSource<Int, FolderItem>!
    private let moveDoneHandler: DoneHandler
    
    private var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.tintColor = .systemPink
        
        navigationItem.title = LocalizingHelper.folderMove
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        cancelBarButtonItem.target = self
        cancelBarButtonItem.action = #selector(cancelBarButtonItemTapped)
        
        view.addSubview(selectedBreadsView)
        selectedBreadsView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectedBreadsView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tableView.delegate = self
        
        configureDataSource()
        
        NotificationCenter.default
            .publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateSelectedBreadsView()
            }
            .store(in: &subscriptions)
    }
    
    override func viewWillLayoutSubviews() {
        updateSelectedBreadsView()
    }
    
    init(model: MoveBreadModel, moveDoneHandler handler: @escaping DoneHandler) {
        self.model = model
        self.moveDoneHandler = handler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("MoveBreadViewController coder not implemented")
    }
}

extension MoveBreadViewController {
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, FolderItem>(tableView: tableView, cellProvider: { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MoveFolderListCell.cellReuseIdentifier, for: indexPath) as? MoveFolderListCell else {
                fatalError("MoveFolderListCell deque failed")
            }
            cell.item = item
            return cell
        })
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, FolderItem>()
        snapshot.appendSections([0])
        
        let createFolderItem = MoveFolderListCell.Item(name: LocalizingHelper.newFolder, disabled: false, objectID: nil)
        snapshot.appendItems([createFolderItem], toSection: 0)
        snapshot.appendItems(model.makeFolderItems(), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
        
        model.didCreateFolderHandler = { [weak self] item in
            guard var snapshot = self?.dataSource.snapshot(),
                  let defaultFolderItem = snapshot.itemIdentifiers[safe: 1] else {
                      return
                  }
            
            snapshot.insertItems([item], afterItem: defaultFolderItem)
            self?.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func updateSelectedBreadsView() {
        let titleAttributes = [NSAttributedString.Key.font: selectedBreadsView.titleFont]
        selectedBreadsView.content = .init(
            text: model.selectedBreadNames(
                inWidth: selectedBreadsView.titleWidth(inWidth: view.frame.width),
                withAttributes: titleAttributes
            ),
            secondaryText: model.selectedBreadsCount()
        )
        selectedBreadsView.invalidateIntrinsicContentSize()
    }
    
}

extension MoveBreadViewController {
    @objc
    private func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }
}

extension MoveBreadViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let folderItem = dataSource.itemIdentifier(for: indexPath)
        return !(folderItem?.disabled ?? true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        if let folderObjectID = selectedItem.objectID {
            model.moveBreads(to: folderObjectID)
            tableView.deselectRow(at: indexPath, animated: true)
            dismiss(animated: true) {
                self.moveDoneHandler()
            }
        
            return
        }
        
        let askingFolderNameAlert = makeAskingFolderNameAlert()
        present(askingFolderNameAlert, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension MoveBreadViewController {
    private func makeAskingFolderNameAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: LocalizingHelper.newFolder,
            message: LocalizingHelper.enterTheNameOfThisFolder,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
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
        
        let cancelAction = UIAlertAction(title: LocalizingHelper.cancel, style: .cancel)
        let doneAction = UIAlertAction(
            title: LocalizingHelper.save,
            style: .default,
            handler: { [weak alert] _ in
                NotificationCenter.default.removeObserver(
                    self,
                    name: UITextField.textDidChangeNotification,
                    object: alert?.textFields?.first
                )
                
                guard let folderName = alert?.textFields?.first?.text?.trimmingCharacters(in: [" "]) else {
                    return
                }
                
                do {
                    try self.model.createFolder(withName: folderName)
                } catch let saveError as ContextSaveError {
                    switch saveError {
                    case .folderNameIsDuplicated, .folderNameIsInBlackList:
                        let errorAlert = BasicAlert.makeConfirmAlert(
                            title: LocalizingHelper.nameIsAlreadyInUse,
                            message: LocalizingHelper.enterDifferentName
                        )
                        self.present(errorAlert, animated: true)
                    case .unknown(let nserror):
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                } catch let nserror as NSError {
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            })
        
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        doneAction.isEnabled = false
        askingFolderNameDoneAction = doneAction
        return alert
    }
}

// MARK: - TextFieldAlertActionEnabling
extension MoveBreadViewController: TextFieldAlertActionEnabling {
    var alertAction: UIAlertAction? {
        askingFolderNameDoneAction
    }
    
    @objc
    private func textDidChange(_ notification: Notification) {
        enableAlertActionByTextCount(notification)
    }
}
