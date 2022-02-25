//
//  MoveBreadViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/11.
//

import UIKit

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
    
    typealias FolderItem = MoveBreadModel.Item
    private let model: MoveBreadModel
    private var dataSource: UITableViewDiffableDataSource<Int, FolderItem>!

    typealias DoneHandler = (() -> Void)
    private let moveDoneHandler: DoneHandler
    
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
            make.height.equalTo(70)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectedBreadsView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tableView.delegate = self
        
        configureDataSource()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViews()
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
        snapshot.appendItems(model.folderItems, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func updateViews() {
        updateSelectedBreadsView()
    }
    
    private func updateSelectedBreadsView() {
        let titleAttributes = [NSAttributedString.Key.font: selectedBreadsView.titleFont]
        selectedBreadsView.content = .init(
            text: model.selectedBreadNames(
                inWidth: selectedBreadsView.titleWidth(),
                withAttributes: titleAttributes
            ),
            secondaryText: model.selectedBreadsCount()
        )
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
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
