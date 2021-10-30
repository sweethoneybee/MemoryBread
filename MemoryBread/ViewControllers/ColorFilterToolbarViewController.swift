//
//  ColorFilterToolbarViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit

protocol ColorFilterToolbarDelegate: AnyObject {
    func colorFilterToolbar(didSelectColorIndex index: Int)
    func colorFilterToolbar(didDeselectColorIndex index: Int)
}

final class ColorFilterToolbarViewController: UIViewController {
    var dataSource: UICollectionViewDiffableDataSource<Section, Int>!
    weak var delegate: ColorFilterToolbarDelegate?
    
    private weak var collectionView: UICollectionView!
    private var selectedItems: [IndexPath]?
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        view = HorizontalToolBar(frame: .zero)
        collectionView = (view as! HorizontalToolBar).collectionView
    }
    
    override func viewDidLoad() {
        configureDataSource()
        
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            selectedItems = collectionView.indexPathsForSelectedItems
            collectionView.deselectAll(animated: animated)
            collectionView.allowsMultipleSelection = !editing
            return
        }
        
        collectionView.allowsMultipleSelection = !editing
        collectionView.deselectAll(animated: animated)
        collectionView.selectAll(selectedItems, animated: animated)
        selectedItems = nil
    }
    
    func deselectAllFilter() {
        collectionView.deselectAll(animated: true)
    }
}

// MARK: - DataSource
extension ColorFilterToolbarViewController {
    enum Section {
        case main
    }
    
    private func configureDataSource() {
        let count = FilterColor.count
        let cellRegistration = UICollectionView.CellRegistration<CircleCell, Int>() { cell, _, item in
            cell.backgroundColor = FilterColor(rawValue: item % count)?.color()
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView, cellProvider: {
            collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        })
        
        reloadDataSource(numberOfItems: count)
    }
    
    func reloadDataSource(numberOfItems: Int) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(0..<numberOfItems)) // Color Values
        dataSource.apply(snapshot)
    }
}

// MARK: - UICollectionViewDelegate
extension ColorFilterToolbarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard isEditing else { return true }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }
        
        if let cell = collectionView.cellForItem(at: indexPath),
           cell.isSelected == false {
            delegate?.colorFilterToolbar(didSelectColorIndex: item)
            return true
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.colorFilterToolbar(didDeselectColorIndex: item)
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isEditing == false else { return }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.colorFilterToolbar(didSelectColorIndex: item)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard isEditing == false else { return }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.colorFilterToolbar(didDeselectColorIndex: item)
    }
}
