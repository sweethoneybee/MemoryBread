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
    
    private var toolbarViewController: ColorFilterToolbarViewController!
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, WordItem>!
    
    private var bread: Bread
    
    private var naviTitleView: ScrollableTitleView!
    private var editContentButtonItem: UIBarButtonItem!
    
    private var wordItems: [WordItem] = []
    private var editingItems: [WordItem] = []
    private var isItemsPanned: [Bool] = []
    private var selectedFilters: Set<Int> = []
    private var editingFilterIndex: Int?
    
    private var highlightedItemIndexForEditing: Int?

    private var currentContentOffset: CGPoint = .zero
    private var sectionTitleViewHeight: CGFloat = 0
    
    private var selectedFilterColor: UIColor? {
        if let editingFilterIndex = editingFilterIndex {
            return FilterColor(rawValue: editingFilterIndex)?.color()
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
        
        sectionTitleViewHeight = bread.title?.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font) ?? 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        if let selectedFilters = bread.selectedFilters {
            toolbarViewController.selectAllFilter(selectedFilters)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bread.selectedFilters = Array(selectedFilters)
        BreadDAO.default.save()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        toolbarViewController.setEditing(editing, animated: animated)
        
        if editing {
            editingItems = copy(wordItems)
            applyNewData(editingItems)
            editContentButtonItem.isEnabled = false
            return
        }
        
        wordItems = copy(editingItems)
        applyNewData(wordItems)
        editContentButtonItem.isEnabled = true
        
        bread.updateFilterIndexes(with: wordItems)
        BreadDAO.default.save()
        
        editingItems.removeAll()
        editingFilterIndex = nil
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
                                                                        elementKind: SupplemantaryTitleView.reuseIdentifier,
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
        editContentButtonItem = UIBarButtonItem(image: UIImage(systemName: "note.text"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(showEditContentViewController))
        navigationItem.rightBarButtonItems = [editButtonItem, editContentButtonItem]
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
        
        if let editingFilterIndex = editingFilterIndex {
            var newItem = WordItem(updatingItem)
            newItem.filterColor = selectedFilterColor
            newItem.isFiltered = selectedFilters.contains(editingFilterIndex)
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
        editContentViewController.didCompleteEditing = didCompleteContentEditing(_:)
        let nvc = UINavigationController(rootViewController: editContentViewController)
        navigationController?.present(nvc, animated: true)
    }
    
    @objc
    private func orientationDidChange(_ notification: Notification) {
        sectionTitleViewHeight = bread.title?.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font) ?? 0
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
            [weak self] cell, indexPath, item in
            guard let self = self else { return }
            cell.label.text = item.word
            
            if self.isEditing == true {
                cell.overlayView.backgroundColor = item.filterColor?.withAlphaComponent(0.5)
                return
            }
            
            if item.isFiltered {
                cell.overlayView.backgroundColor = item.isPeeking ? item.filterColor?.withAlphaComponent(0.5) : item.filterColor
                return
            }
            
            cell.overlayView.backgroundColor = .clear
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <SupplemantaryTitleView>(elementKind: SupplemantaryTitleView.reuseIdentifier) {
            [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            supplementaryView.label.text = self.bread.title
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapSupplementaryTitleView(_:)))
            supplementaryView.label.addGestureRecognizer(tapGesture)
            supplementaryView.label.isUserInteractionEnabled = true
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, WordItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            return self?.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
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
        
        collectionView.setContentOffset(currentContentOffset, animated: false)
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
    
    private func didCompleteContentEditing(_ newContent: String) {
        let newContent = newContent.trimmingCharacters(in: [" "])
        guard bread.content != newContent else { return }
        
        bread.updateContent(newContent)
        bread.selectedFilters?.removeAll()
        BreadDAO.default.save()
        
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
            editingFilterIndex = index
            return
        }
        selectedFilters.insert(index)
        updateFilteringWordItems(by: index, to: true)
    }
    
    private func filterDeselected(at index: Int) {
        if isEditing {
            editingFilterIndex = nil
            return
        }
        selectedFilters.remove(index)
        updateFilteringWordItems(by: index, to: false)
    }
    
    private func updateFilteringWordItems(by filterValue: Int, to isFiltered: Bool) {
        var newItems = copy(wordItems)
        bread.filterIndexes?[filterValue].forEach {
            newItems[$0].isFiltered = isFiltered
            newItems[$0].isPeeking = false
        }
        applyNewData(newItems)
        wordItems = newItems
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BreadViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if editingFilterIndex != nil {
            return false
        }
        return true
    }
}

// MARK: - UIScrollViewDelegate
extension BreadViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentContentOffset = scrollView.contentOffset
        updateNaviTitleViewShowingIfNeeded()
    }
    
    private func updateNaviTitleViewShowingIfNeeded() {
        if currentContentOffset.y >= sectionTitleViewHeight {
            if navigationItem.titleView == nil {
                navigationItem.titleView = naviTitleView
            }
            return
        }
        
        if currentContentOffset.y < sectionTitleViewHeight {
            if navigationItem.titleView != nil {
                navigationItem.titleView = nil
            }
            return
        }
    }
}

// MARK: - Alert
extension BreadViewController {
    @objc private func didTapSupplementaryTitleView(_ sender: UITapGestureRecognizer) {
        let titleEditAlert = UIAlertController(title: "제목 변경", message: nil, preferredStyle: .alert)
        titleEditAlert.addTextField { [weak self] textField in
            textField.clearButtonMode = .always
            textField.returnKeyType = .done
            textField.text = self?.bread.title
        }
        
        titleEditAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        titleEditAlert.addAction(UIAlertAction(title: "완료", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let inputText = titleEditAlert.textFields?.first?.text {
                self.bread.updateTitle(inputText)
                BreadDAO.default.save()
                self.updateTitleViews(using: inputText)
            }
        })
        
        present(titleEditAlert, animated: true)
    }
    
    private func updateTitleViews(using title: String) {
        naviTitleView.text = bread.title
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.main])
        dataSource.apply(snapshot)
    }
}
