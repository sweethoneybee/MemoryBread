//
//  BreadListViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/31.
// 'ImplementingModernCollectionViews' sample code from Apple
// 

import UIKit
import SnapKit

final class BreadListViewController: UIViewController {
    enum Section {
        case main
    }
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, BreadListController.BreadItem>!
    
    var breadListController = BreadListController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "암기빵"
        navigationItem.backButtonDisplayMode = .minimal
        configureHierarchy()
        configureDataSource()
        addToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let breadItems = breadListController.items
        var snapshot = NSDiffableDataSourceSnapshot<Section, BreadListController.BreadItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(breadItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Configure Views
extension BreadListViewController {
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .breadList
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func addToolbar() {
        let addItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(addBread))
        addItem.tintColor = .systemPink
        navigationItem.rightBarButtonItem = addItem
    }
    
    @objc
    func addBread() {
        
    }
}

// MARK: - Data Source
extension BreadListViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration
        <BreadListCell, BreadListController.BreadItem> { cell, indexPath, breadItem in
            cell.titleLabel.text = breadItem.title
            cell.bodyLabel.text = breadItem.body
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale(identifier: "ko-KR")
            cell.dateLabel.text = dateFormatter.string(from: breadItem.date)
        }
        
        dataSource = UICollectionViewDiffableDataSource
        <Section, BreadListController.BreadItem>(collectionView: collectionView) {
            collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        let breadItems = breadListController.items
        var snapshot = NSDiffableDataSourceSnapshot<Section, BreadListController.BreadItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(breadItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - CollecionView Delegate
extension BreadListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let bread = breadListController.getBread(at: indexPath.item)
        let breadViewController = BreadViewController(bread: bread)
        navigationController?.pushViewController(breadViewController, animated: true)
    }
}
