//
//  BreadViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit

final class BreadViewController: UIViewController {
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
            reloadDataSource(with: editingItems)
            return
        }
        
        wordItems = copy(editingItems ?? [WordItem]())
        
        reloadDataSource(with: wordItems)
        
        updateFilterIndexes(with: wordItems)
        editingItems = nil
        selectedFilterWithEditing = nil
    }
}

// MARK: - Configure Views
extension BreadViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50),
                                              heightDimension: .estimated(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(50))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        configureLayouts()
    }
    
    private func configureLayouts() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
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
        navigationItem.title = "타이틀"
        
        let editContentItem = UIBarButtonItem(image: UIImage(systemName: "note.text"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(showEditContentViewController))
        navigationItem.rightBarButtonItems = [editButtonItem, editContentItem]
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
        nvc.navigationBar.backgroundColor = .systemBackground
        navigationController?.present(nvc, animated: true)
    }
}

// MARK: - Diffable Data Source
extension BreadViewController {
    enum Section {
        case main
    }
    
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
            self.filterColor = item.filterColor
            self.isFiltered = item.isFiltered
            self.isPeeking = item.isPeeking
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(isFiltered)
            hasher.combine(filterColor)
            hasher.combine(isPeeking)
        }
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.identifier == rhs.identifier
            && lhs.isFiltered == rhs.isFiltered
            && lhs.filterColor == rhs.filterColor
            && lhs.isPeeking == rhs.isPeeking
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCell, WordItem> {
            [weak self] cell, indexPath, item in
            cell.label.text = item.word
            
            if self?.isEditing == true {
                cell.backgroundColor = item.filterColor?.withAlphaComponent(0.5)
                cell.label.textColor = .black
                return
            }
            
            if item.isFiltered {
                cell.backgroundColor = item.isPeeking ? item.filterColor?.withAlphaComponent(0.5) : item.filterColor
                cell.label.textColor = item.isPeeking ? .black : item.filterColor
                return
            }
            
            cell.backgroundColor = .clear
            cell.label.textColor = .black
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, WordItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        reloadDataSource(with: wordItems)
    }
    
    private func reloadDataSource(with items: [WordItem]?) {
        guard let items = items else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, WordItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
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
    
    private func updateFilterIndexes(with items: [WordItem]) {
        var filterIndexes: [[Int]] = Array(repeating: [], count: FilterColor.count)
        wordItems.enumerated().forEach { (itemIndex, item) in
            if let colorIndex = FilterColor.colorIndex(for: item.filterColor) {
                filterIndexes[colorIndex].append(itemIndex)
            }
        }
        bread.filterIndexes = filterIndexes
        bread.touch = Date.now
        BreadDAO().save()
    }
    
    private func didCompleteEditing(_ newContent: String) {
        let newContent = newContent.trimmingCharacters(in: [" "])
        guard bread.content != newContent else { return }
        
        bread.content = newContent
        bread.separatedContent = newContent.components(separatedBy: ["\n", " "])
        bread.filterIndexes = Array(repeating: [], count: FilterColor.count)
        bread.touch = Date.now
        BreadDAO().save()
        
        wordItems = populateData(from: bread)
        reloadDataSource(with: wordItems)
        
        filterReset()
    }
    
    private func filterReset() {
        toolbarViewController.deselectAllFilter()
        selectedFilters.removeAll()
    }
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let index = indexPath.item
        guard isEditing else {
            wordItems[index].isPeeking.toggle()
            reloadDataSource(with: wordItems)
            return
        }
        
        guard let editingFilter = selectedFilterWithEditing,
              let filterColor = FilterColor(rawValue: editingFilter)?.color() else {
                  editingItems?[index].filterColor = nil
                  editingItems?[index].isFiltered = false
                  editingItems?[index].isPeeking = false
                  reloadDataSource(with: editingItems)
                  return
              }
        
        if editingItems?[index].filterColor == filterColor {
            editingItems?[index].filterColor = nil
            editingItems?[index].isFiltered = false
            editingItems?[index].isPeeking = false
            reloadDataSource(with: editingItems)
            return
        }
        
        editingItems?[index].filterColor = filterColor
        editingItems?[index].isFiltered = selectedFilters.contains(editingFilter)
        reloadDataSource(with: editingItems)
    }
}

// MARK: - ColorFilterToolbar Delegate
extension BreadViewController: ColorFilterToolbarDelegate {
    func colorFilterToolbar(didSelectColorIndex index: Int) {
        if isEditing {
            selectedFilterWithEditing = index
            return
        }
        filterSelected(at: index, isSelected: true)
        selectedFilters.insert(index)
    }
    
    func colorFilterToolbar(didDeselectColorIndex index: Int) {
        if isEditing {
            selectedFilterWithEditing = nil
            return
        }
        filterSelected(at: index, isSelected: false)
        selectedFilters.remove(index)
    }
    
    private func filterSelected(at index: Int, isSelected: Bool) {
        bread.filterIndexes?[index].forEach {
            wordItems[$0].isFiltered = isSelected
            wordItems[$0].isPeeking = false
        }
        reloadDataSource(with: wordItems)
    }
}
