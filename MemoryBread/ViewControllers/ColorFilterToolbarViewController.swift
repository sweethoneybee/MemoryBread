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
    weak var delegate: ColorFilterToolbarDelegate?
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>!
    
    private weak var collectionView: UICollectionView!
    private var selectedFilters: [IndexPath]?
    
    private var numberOfEachFilterIndexes: [Int] = Array(repeating: 0, count: FilterColor.count)
    
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
            selectedFilters = collectionView.indexPathsForSelectedItems
            collectionView.deselectAll(animated: animated)
            collectionView.allowsMultipleSelection = !editing
            return
        }
        
        collectionView.allowsMultipleSelection = !editing
        collectionView.deselectAll(animated: animated)
        collectionView.selectAll(selectedFilters, animated: animated)
        selectedFilters = nil
    }
    
    func select(_ selectedIndexes: [Int]) {
        selectedIndexes.forEach {
            collectionView.selectItem(at: IndexPath(row: $0, section: 0), animated: false, scrollPosition: [])
            delegate?.colorFilterToolbar(didSelectColorIndex: $0)
        }
    }
    
    func deselectAllFilter() {
        collectionView.deselectAll(animated: true)
    }
    
    func showNumberOfFilterIndexes(using filterIndexes: [[Int]]?) {
        if let filterIndexes = filterIndexes {
            numberOfEachFilterIndexes = filterIndexes.map { $0.count }
        } else {
            numberOfEachFilterIndexes = Array(repeating: 0, count: numberOfEachFilterIndexes.count)
        }
        
        dataSource.reconfigure(Array(0..<numberOfEachFilterIndexes.count), animatingDifferences: false)
    }
}

// MARK: - DataSource
extension ColorFilterToolbarViewController {
    enum Section {
        case main
    }
    
    private func configureDataSource() {
        let count = FilterColor.count
        let cellRegistration = UICollectionView.CellRegistration<CircleCell, Int>() { [weak self] cell, _, item in
            guard let self = self else { return }
            cell.backgroundColor = FilterColor(rawValue: item % count)?.color()
            
            if self.isEditing {
                cell.text = "편집"
            } else {
                let text = self.numberOfEachFilterIndexes[item % count] == 0 ? "" : "\(self.numberOfEachFilterIndexes[item % count])"
                cell.text = text
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView, cellProvider: {
            collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        })
        
        apply(numberOfItems: count)
    }
    
    private func apply(numberOfItems: Int) {
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
