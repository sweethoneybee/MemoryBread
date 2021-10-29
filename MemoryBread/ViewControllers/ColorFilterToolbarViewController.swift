//
//  ColorFilterToolbarViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit

enum FilterColor: Int, CaseIterable {
    case red, blue, yellow, brown
    func color() -> UIColor {
        switch self {
        case .red: return UIColor.red
        case .blue: return UIColor.blue
        case .yellow: return UIColor.yellow
        case .brown: return UIColor.brown
        }
    }
    
    static var count: Int {
        FilterColor.allCases.count
    }
    
    static func colorIndex(for color: UIColor?) -> Int? {
        guard let color = color else { return nil }
        switch color {
        case .red: return FilterColor.red.rawValue
        case .blue: return FilterColor.blue.rawValue
        case .yellow: return FilterColor.yellow.rawValue
        case .brown: return FilterColor.brown.rawValue
        default: return nil
        }
    }
}

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
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.colorFilterToolbar(didSelectColorIndex: item)
    }
     
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.colorFilterToolbar(didDeselectColorIndex: item)
    }
}
