//
//  BreadViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit

final class BreadViewController: UIViewController {
    struct UIConstants {
        static let inset: CGFloat = 20
    }
    
    enum Section {
        case main
    }
    
    var toolbarViewController: ColorFilterToolbarViewController!
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, WordItem>!
    
    var bread: Bread
    private var wordItems: [WordItem] = []
    private var editingItems: [WordItem]?
    private var selectedFilters: Set<Int> = []
    private var selectedFilterWithEditing: Int?

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(bread: Bread) {
        self.bread = bread
        super.init(nibName: nil, bundle: nil)
        self.wordItems = self.populateData(from: self.bread)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureHierarchy()
        configureDataSource()
        configureNavigation()
        
        addToolbar()
        
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        
        toolbarViewController.delegate = self
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        toolbarViewController.setEditing(editing, animated: animated)
        
        if editing {
            editingItems = copy(wordItems)
            applyNewData(editingItems ?? [])
            return
        }
        
        wordItems = copy(editingItems ?? [])
        applyNewData(wordItems)
        
        bread.updateFilterIndexes(with: wordItems)
        BreadDAO().save()
        
        editingItems = nil
        selectedFilterWithEditing = nil
    }
}

// MARK: - Configure Views
extension BreadViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(10),
                                              heightDimension: .estimated(10))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(10))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(5)
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .breadBody
        view.addSubview(collectionView)
        
        configureLayouts()
    }
    
    private func configureLayouts() {
        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(UIConstants.inset)
        }
    }
    
    private func addToolbar() {
        toolbarViewController = ColorFilterToolbarViewController()
        addChild(toolbarViewController)
        view.addSubview(toolbarViewController.view)
        toolbarViewController.didMove(toParent: self)
        
        toolbarViewController.view.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(100)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
    
    private func configureNavigation() {
        let editContentItem = UIBarButtonItem(image: UIImage(systemName: "note.text"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(showEditContentViewController))
        navigationItem.rightBarButtonItems = [editButtonItem, editContentItem]
        navigationItem.largeTitleDisplayMode = .never
    }
}

// MARK: - objc methods
extension BreadViewController {
    @objc
    private func showEditContentViewController() {
        guard isEditing == false,
              let content = bread.content else { return }
        
        let editContentViewController = EditContentViewController(content: content)
        editContentViewController.didCompleteEditing = didCompleteEditing(_:)
        let nvc = UINavigationController(rootViewController: editContentViewController)
        navigationController?.present(nvc, animated: true)
    }
}

// MARK: - Diffable Data Source
extension BreadViewController {
    struct WordItem: Hashable {
        let identifier = UUID()
        let word: String
        var isFiltered: Bool = false
        var isPeeking: Bool = false
        var filterColor: UIColor?
  
        init(word: String) {
            self.word = word
        }
        
        init(_ item: Self) {
            self.word = item.word
            self.isFiltered = item.isFiltered
            self.isPeeking = item.isPeeking
            self.filterColor = item.filterColor
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCell, WordItem> {
            [weak self] cell, indexPath, item in
            cell.label.text = item.word
            
            if self?.isEditing == true {
                cell.backgroundColor = item.filterColor?.withAlphaComponent(0.5)
                cell.label.textColor = .wordCellText
                return
            }
            
            if item.isFiltered {
                cell.backgroundColor = item.isPeeking ? item.filterColor?.withAlphaComponent(0.5) : item.filterColor
                cell.label.textColor = item.isPeeking ? .wordCellText : item.filterColor
                return
            }
            
            cell.backgroundColor = .clear
            cell.label.textColor = .wordCellText
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, WordItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, WordItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(wordItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func applyNewData(_ newItems: [WordItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, WordItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(newItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func reloadDataSource(from oldItems: [WordItem], to newItems: [WordItem]) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(oldItems)
        snapshot.appendItems(newItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func reloadItem(from oldItem: WordItem, to newItem: WordItem) {
        var snapshot = dataSource.snapshot()
        snapshot.insertItems([newItem], afterItem: oldItem)
        snapshot.deleteItems([oldItem])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Data Modifier
extension BreadViewController {
    private func populateData(from bread: Bread) -> [WordItem] {
        guard let separatedContent = bread.separatedContent,
              let filterIndexes = bread.filterIndexes else {
                  return [WordItem]()
              }
        
        var wordItems = separatedContent.map { WordItem(word: $0) }
        filterIndexes.enumerated().forEach { (colorValue, wordIndexes) in
            wordIndexes.forEach {
                wordItems[$0].filterColor = FilterColor(rawValue: colorValue)?.color()
            }
        }
        
        return wordItems
    }
    
    private func copy(_ items: [WordItem]) -> [WordItem] {
        return items.map { WordItem($0) }
    }
    
    private func didCompleteEditing(_ newContent: String) {
        let newContent = newContent.trimmingCharacters(in: [" "])
        guard bread.content != newContent else { return }
        
        bread.updateContent(newContent)
        BreadDAO().save()
        
        wordItems = populateData(from: bread)
        applyNewData(wordItems)
        
        toolbarViewController.deselectAllFilter()
        selectedFilters.removeAll()
    }
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let index = indexPath.item
        guard isEditing else {
            if let colorIndex = FilterColor.colorIndex(for: wordItems[index].filterColor),
               selectedFilters.contains(colorIndex) {
                var newItem = WordItem(wordItems[index])
                newItem.isPeeking.toggle()
                reloadItem(from: wordItems[index], to: newItem)
                wordItems[index] = newItem
            }
            return
        }
        
        guard let oldItem = editingItems?[index] else { return }
        guard let editingFilter = selectedFilterWithEditing,
              let filterColor = FilterColor(rawValue: editingFilter)?.color() else {
                  if editingItems?[index].filterColor != nil {
                      var newItem = WordItem(oldItem)
                      newItem.filterColor = nil
                      newItem.isFiltered = false
                      newItem.isPeeking = false
                      reloadItem(from: oldItem, to: newItem)
                      editingItems?[index] = newItem
                  }
                  return
              }
        
        if oldItem.filterColor == filterColor {
            var newItem = WordItem(oldItem)
            newItem.filterColor = nil
            newItem.isFiltered = false
            newItem.isPeeking = false
            reloadItem(from: oldItem, to: newItem)
            editingItems?[index] = newItem
            return
        }
        
        var newItem = WordItem(oldItem)
        newItem.filterColor = filterColor
        newItem.isFiltered = selectedFilters.contains(editingFilter)
        reloadItem(from: oldItem, to: newItem)
        editingItems?[index] = newItem
    }
}

// MARK: - ColorFilterToolbar Delegate
extension BreadViewController: ColorFilterToolbarDelegate {
    func colorFilterToolbar(didSelectColorIndex index: Int) {
        filterSelected(at: index)
    }
    
    func colorFilterToolbar(didDeselectColorIndex index: Int) {
        filterDeselected(at: index)
    }
    
    private func filterSelected(at index: Int) {
        if isEditing {
            selectedFilterWithEditing = index
            return
        }
        selectedFilters.insert(index)
        filteringWordItems(using: index)
    }
    
    private func filterDeselected(at index: Int) {
        if isEditing {
            selectedFilterWithEditing = nil
            return
        }
        selectedFilters.remove(index)
        unfilteringWordItems(using: index)
    }
    
    private func filteringWordItems(using filterValue: Int) {
        let oldItems = wordItems
        var newItems = oldItems
        bread.filterIndexes?[filterValue].forEach {
            newItems[$0] = WordItem(oldItems[$0])
            newItems[$0].isFiltered = true
            newItems[$0].isPeeking = false
        }
        reloadDataSource(from: oldItems, to: newItems)
        wordItems = newItems
    }
    
    private func unfilteringWordItems(using filterValue: Int) {
        let oldItems = wordItems
        var newItems = oldItems
        bread.filterIndexes?[filterValue].forEach {
            newItems[$0] = WordItem(oldItems[$0])
            newItems[$0].isFiltered = false
            newItems[$0].isPeeking = false
        }
        reloadDataSource(from: oldItems, to: newItems)
        wordItems = newItems
    }
}
