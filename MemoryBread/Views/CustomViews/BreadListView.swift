//
//  BreadListView.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/02/02.
//

import UIKit

protocol BreadListViewDelegate: AnyObject {
    func createBreadButtonTouched()
    func deleteButtonTouched(selectedIndexPaths rows: [IndexPath]?)
    func deleteAllButtonTouched()
}

extension BreadListViewDelegate {
    func createBreadButtonTouched() {}
}

final class BreadListView: UIView {
    
    weak var delegate: BreadListViewDelegate?
    
    let tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.allowsMultipleSelectionDuringEditing = true
        $0.register(BreadListCell.self, forCellReuseIdentifier: BreadListCell.reuseIdentifier)
    }

    private let tableViewHeaderLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .thin)
        $0.textAlignment = .center
        $0.frame.size.height = 30
    }
    
    private var createBreadButton: UIButton?
    
    private let bottomToolbar = BottomToolbar(frame: .init(x: 0, y: 0, width: 200, height: 100)).then {
        $0.isHidden = true
    }
    
    private let bottomDeleteButton = UIButton(type: .system).then {
        $0.setTitle(LocalizingHelper.delete, for: .normal)
    }
    
    private let bottomDeleteAllButton = UIButton(type: .system).then {
        $0.setTitle(LocalizingHelper.deleteAll, for: .normal)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
        configureLayouts()
    }
    
    init(isCreateButtonAvailable: Bool = true) {
        super.init(frame: .zero)
        if isCreateButtonAvailable {
            self.createBreadButton = UIButton(type: .system).then {
                $0.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            }
        }
        
        setUp()
        configureLayouts()
    }
}

// MARK: - Custom
extension BreadListView {
    var headerLabelText: String? {
        get {
            tableViewHeaderLabel.text
        }
        set {
            tableViewHeaderLabel.text = newValue
        }
    }
}

// MARK: - Set up
extension BreadListView {
    private func setUp() {
        addSubview(tableView)
        tableView.tableHeaderView = tableViewHeaderLabel
        
        addSubview(bottomToolbar)
        bottomToolbar.addArrangedSubview(bottomDeleteButton, to: .right)
        bottomToolbar.addArrangedSubview(bottomDeleteAllButton, to: .right)
        bottomDeleteButton.addTarget(self, action: #selector(bottomDeleteButtonTouched), for: .touchUpInside)
        bottomDeleteAllButton.addTarget(self, action: #selector(bottomDeleteAllButtonTouched), for: .touchUpInside)
        
        if let createBreadButton = createBreadButton {
            addSubview(createBreadButton)
            createBreadButton.addTarget(self, action: #selector(createBreadButtonTouched), for: .touchUpInside)
        }
    }
    
    private func configureLayouts() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        createBreadButton?.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).offset(-20)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        createBreadButton?.imageView?.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        bottomToolbar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.bottom.equalToSuperview()
            make.bottom.leading.trailing.equalToSuperview()
        }
    }
}

// MARK: - Interface
extension BreadListView {
    func setEditing(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
    }
    
    struct State {
        let isEditing: Bool
        let numberOfSelectedRows: Int
    }
    
    func updateUI(for state: State) {
        createBreadButton?.isHidden = state.isEditing
        bottomToolbar.isHidden = !state.isEditing
        
        bottomDeleteButton.isHidden = (state.numberOfSelectedRows == 0)
        bottomDeleteAllButton.isHidden = !(bottomDeleteButton.isHidden)
        
        if state.isEditing {
            createBreadButton?.layer.opacity = 0
            bottomToolbar.layer.opacity = 1
        } else {
            createBreadButton?.layer.opacity = 1
            bottomToolbar.layer.opacity = 0
        }
    }
}

extension BreadListView {
    @objc
    func createBreadButtonTouched() {
        delegate?.createBreadButtonTouched()
    }
    
    @objc
    func bottomDeleteButtonTouched() {
        delegate?.deleteButtonTouched(selectedIndexPaths: tableView.indexPathsForSelectedRows)
    }
    
    @objc
    func bottomDeleteAllButtonTouched() {
        delegate?.deleteAllButtonTouched()
    }
}

