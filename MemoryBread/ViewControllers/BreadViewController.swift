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
    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>!
    
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
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
        
        sectionTitleViewHeight = bread.title?.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font) ?? 0
        
        if let selectedFilters = bread.selectedFilters {
            toolbarViewController.selectAllFilter(selectedFilters)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
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
            editingItems = wordItems
            reconfigureItems(animatingDifferences: true)
            editContentButtonItem.isEnabled = false
            
            toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
            return
        }
        
        wordItems = editingItems
        reconfigureItems(animatingDifferences: true)
        editContentButtonItem.isEnabled = true
        
        bread.updateFilterIndexes(with: wordItems)
        BreadDAO.default.save()
        
        editingItems.removeAll()
        editingFilterIndex = nil
        highlightedItemIndexForEditing = nil
        
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
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

// MARK: - Diffable Data Source
extension BreadViewController {
    struct WordItem: Identifiable {
        let id: Int
        let word: String
        var isFiltered: Bool = false
        var isPeeking: Bool = false
        var filterColor: UIColor?
  
        init(id: Int, word: String) {
            self.id = id
            self.word = word
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCell, Int> {
            [weak self] cell, indexPath, id in
            guard let self = self else { return }
            
            if self.isEditing {
                let editItem = self.editingItems[id]
                cell.label.text = editItem.word
                cell.overlayView.backgroundColor = editItem.filterColor?.withAlphaComponent(0.5) ?? .clear
                return
            }
            
            let item = self.wordItems[id]
            cell.label.text = item.word
            
            if item.isFiltered {
                cell.overlayView.backgroundColor = item.isPeeking ? (item.filterColor?.withAlphaComponent(0.5)) : (item.filterColor)
            } else {
                cell.overlayView.backgroundColor = .clear
            }
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
        
        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView) { collectionView, indexPath, id in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            return self?.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
        
        applyNewItems(wordItems)
    }
    
    private func applyNewItems(_ newItems: [WordItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(wordItems.map{ $0.id }, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func reconfigureItems(animatingDifferences: Bool) {
        // wordItems, editingItems가 같은 id를 사용하기 때문에 분기를 타더라도 동작은 동일함.
        var snapshot = dataSource.snapshot()
        if isEditing {
            snapshot.reconfigureItems(editingItems.map { $0.id })
            dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        } else {
            snapshot.reconfigureItems(wordItems.map { $0.id })
            dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        }
    }
    
    private func reconfigureItem(_ item: WordItem, animatingDifferences: Bool) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([item.id])
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

// MARK: - Data Modifier
extension BreadViewController {
    private func populateData(from bread: Bread) -> [WordItem] {
        guard let separatedContent = bread.separatedContent,
              let filterIndexes = bread.filterIndexes else {
                  return [WordItem]()
              }
        
        var wordItems = separatedContent.enumerated().map { WordItem(id: $0, word: $1) }
        filterIndexes.enumerated().forEach { (colorValue, wordIndexes) in
            wordIndexes.forEach {
                wordItems[$0].filterColor = FilterColor(rawValue: colorValue)?.color()
            }
        }
        
        return wordItems
    }
    
    private func didCompleteContentEditing(_ newContent: String) {
        let newContent = newContent.trimmingCharacters(in: [" "])
        guard bread.content != newContent else { return }
        
        bread.updateContent(newContent)
        bread.selectedFilters?.removeAll()
        BreadDAO.default.save()
        
        wordItems = populateData(from: bread)
        applyNewItems(wordItems)
        reconfigureItems(animatingDifferences: false)
        
        toolbarViewController.deselectAllFilter()
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
        selectedFilters.removeAll()
    }
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let index = indexPath.item
        
        if isEditing {
            highlightedItemIndexForEditing = index
            updateEditingItemIfNeeded(at: index)
            return
        }
        
        if let colorIndex = FilterColor.colorIndex(for: wordItems[index].filterColor),
           selectedFilters.contains(colorIndex) {
            wordItems[index].isPeeking.toggle()
            reconfigureItem(wordItems[index], animatingDifferences: true)
        }
    }
    
    private func updateEditingItemIfNeeded(at index: Int) {
        guard isEditing,
              index < editingItems.count else {
                  return
              }
        
        var editItem = editingItems[index]
        if selectedFilterColor == nil { // 편집 중 필터 선택 X
            if editItem.filterColor != nil {
                editItem.filterColor = nil
                editItem.isFiltered = false
                editItem.isPeeking = false
                editingItems[index] = editItem
                reconfigureItem(editItem, animatingDifferences: true)
            }
            return
        }
        
        // 편집 중 필터 선택 O.
        if editItem.filterColor == selectedFilterColor {
            editItem.filterColor = nil
            editItem.isFiltered = false
            editItem.isPeeking = false
            editingItems[index] = editItem
            reconfigureItem(editItem, animatingDifferences: true)
            return
        }
        
        if let editingFilterIndex = editingFilterIndex {
            editItem.filterColor = selectedFilterColor
            editItem.isFiltered = selectedFilters.contains(editingFilterIndex)
            editingItems[index] = editItem
            reconfigureItem(editItem, animatingDifferences: true)
        }
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
        bread.filterIndexes?[filterValue].forEach {
            wordItems[$0].isFiltered = isFiltered
            wordItems[$0].isPeeking = false
        }
        reconfigureItems(animatingDifferences: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BreadViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if editingFilterIndex == nil {
            return true
        }
        return false
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
        guard isEditing,
        editingFilterIndex != nil else { return }
        
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
                updateEditingItemIfNeeded(at: index)
            }
        default:
            break
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
