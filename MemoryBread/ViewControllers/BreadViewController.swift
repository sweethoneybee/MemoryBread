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
        static let edgeInset: CGFloat = 20
        static let wordItemSpacing: CGFloat = 5
        static let lineSpacing: CGFloat = 15
        static let backButtonOffset: CGFloat = -10
    }
    
    enum Section {
        case main
    }
    
    var toolbarViewController: ColorFilterToolbarViewController!
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, WordItem>!
    
    var bread: Bread
    
    var naviTitleView: UIView!
    
    private var wordItems: [WordItem] = []
    private var editingItems: [WordItem] = []
    private var isItemsPanned: [Bool] = []
    private var selectedFilters: Set<Int> = []
    private var selectedFilterIndex: Int?
    
    private var highlightedItemIndexForEditing: Int?

    private var currentContentOffsetY: CGFloat = .zero
    private var sectionTitleViewHeight: CGFloat = 0
    
    private var selectedFilterColor: UIColor? {
        if let selectedFilterIndex = selectedFilterIndex {
            return FilterColor(rawValue: selectedFilterIndex)?.color()
        }
        return nil
    }
    
    private var collectionViewContentWidth: CGFloat {
        return view.safeAreaLayoutGuide.layoutFrame.width - UIConstants.edgeInset * 2
    }
    
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
        
        addGesture()
        
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        
        toolbarViewController.delegate = self
        
        sectionTitleViewHeight = bread.title?.height(withConstraintWidth: collectionViewContentWidth, font: ScrollableSupplemantaryView.font) ?? 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        toolbarViewController.setEditing(editing, animated: animated)
        
        if editing {
            editingItems = copy(wordItems)
            applyNewData(editingItems)
            return
        }
        
        wordItems = copy(editingItems)
        applyNewData(wordItems)
        
        bread.updateFilterIndexes(with: wordItems)
        BreadDAO().save()
        
        editingItems.removeAll()
        selectedFilterIndex = nil
        highlightedItemIndexForEditing = nil
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
        group.interItemSpacing = .fixed(UIConstants.wordItemSpacing)
    
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = UIConstants.lineSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: UIConstants.edgeInset, bottom: 0, trailing: UIConstants.edgeInset)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                        elementKind: ScrollableSupplemantaryView.reuseIdentifier,
                                                                        alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .breadBody

        view.addSubview(collectionView)
        
        addToolbar()
        
        configureLayouts()
    }
    
    private func configureLayouts() {
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(toolbarViewController.view.snp.top)
        }
        
        toolbarViewController.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-HorizontalToolBar.UIConstants.groupHeight)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
    
    private func addToolbar() {
        toolbarViewController = ColorFilterToolbarViewController()
        addChild(toolbarViewController)
        view.addSubview(toolbarViewController.view)
        toolbarViewController.didMove(toParent: self)
    }
    
    private func configureNavigation() {
        let editContentItem = UIBarButtonItem(image: UIImage(systemName: "note.text"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(showEditContentViewController))
        navigationItem.rightBarButtonItems = [editButtonItem, editContentItem]
        navigationItem.largeTitleDisplayMode = .never

        naviTitleView = ScrollableTitleView(frame: .zero).then {
            $0.text = bread.title
        }
    }
}

// MARK: - Gesture
extension BreadViewController {
    private func addGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panningWords(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        collectionView.addGestureRecognizer(panGesture)
    }
    
    @objc
    private func panningWords(_ sender: UIGestureRecognizer) {
        guard isEditing else { return }
        
        switch sender.state {
        case .began:
            isItemsPanned = Array(repeating: false, count: editingItems.count)
            if let justHighlighted = highlightedItemIndexForEditing {
                isItemsPanned[justHighlighted] = true
                highlightedItemIndexForEditing = nil
            }
        case .changed:
            let touchedPoint = sender.location(in: collectionView)
            if let index = collectionView.indexPathForItem(at: touchedPoint)?.item,
               index < isItemsPanned.count,
               isItemsPanned[index] == false {
                isItemsPanned[index] = true
                updateItemIfNeeded(at: index)
            }
        default:
            break
        }
    }
    
    private func updateItemIfNeeded(at index: Int) {
        guard isEditing,
              index < editingItems.count else {
                  return
              }
        
        let updatingItem = editingItems[index]
        
        if selectedFilterColor == nil { // 편집 중 필터 선택 X
            if updatingItem.filterColor != nil {
                let newItem = removeFilterOf(oldItem: updatingItem)
                reloadItem(from: updatingItem, to: newItem)
                editingItems[index] = newItem
            }
            return
        }
        
        // 편집 중 필터 선택 O.
        if updatingItem.filterColor == selectedFilterColor {
            let newItem = removeFilterOf(oldItem: updatingItem)
            reloadItem(from: updatingItem, to: newItem)
            editingItems[index] = newItem
            return
        }
        
        if let selectedFilterIndex = selectedFilterIndex {
            var newItem = WordItem(updatingItem)
            newItem.filterColor = selectedFilterColor
            newItem.isFiltered = selectedFilters.contains(selectedFilterIndex)
            reloadItem(from: updatingItem, to: newItem)
            editingItems[index] = newItem
        }
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
    
    @objc
    private func orientationDidChange(_ notification: Notification) {
        sectionTitleViewHeight = bread.title?.height(withConstraintWidth: collectionViewContentWidth, font: ScrollableSupplemantaryView.font) ?? 0
        updateNaviTitleViewShowingIfNeeded()
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
            cell, indexPath, item in
            cell.label.text = item.word
            
            if self.isEditing == true {
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
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <ScrollableSupplemantaryView>(elementKind: ScrollableSupplemantaryView.reuseIdentifier) { supplementaryView, elementKind, indexPath in
            supplementaryView.label.text = self.bread.title
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, WordItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { (view, kind, index) in
            return self.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
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
        
        if isEditing {
            highlightedItemIndexForEditing = index
            updateItemIfNeeded(at: index)
            return
        }
        
        if let colorIndex = FilterColor.colorIndex(for: wordItems[index].filterColor),
           selectedFilters.contains(colorIndex) {
            var newItem = WordItem(wordItems[index])
            newItem.isPeeking.toggle()
            reloadItem(from: wordItems[index], to: newItem)
            wordItems[index] = newItem
        }
    }
    
    private func removeFilterOf(oldItem: WordItem) -> WordItem {
        var newItem = WordItem(oldItem)
        newItem.filterColor = nil
        newItem.isFiltered = false
        newItem.isPeeking = false
        return newItem
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
            selectedFilterIndex = index
            return
        }
        selectedFilters.insert(index)
        filteringWordItems(using: index)
    }
    
    private func filterDeselected(at index: Int) {
        if isEditing {
            selectedFilterIndex = nil
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

// MARK: - UIGestureRecognizerDelegate
extension BreadViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if selectedFilterIndex != nil {
            return false
        }
        return true
    }
}

// MARK: - UIScrollViewDelegate
extension BreadViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentContentOffsetY = scrollView.contentOffset.y
        updateNaviTitleViewShowingIfNeeded()
    }
    
    private func updateNaviTitleViewShowingIfNeeded() {
        if currentContentOffsetY >= sectionTitleViewHeight {
            if navigationItem.titleView == nil {
                navigationItem.titleView = naviTitleView
            }
            return
        }
        
        if currentContentOffsetY < sectionTitleViewHeight {
            if navigationItem.titleView != nil {
                navigationItem.titleView = nil
            }
            return
        }
    }
}
