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
    
    private var naviTitleView: ScrollableTitleView!
    private var editContentButtonItem: UIBarButtonItem!
    private var toolbarViewController: ColorFilterToolbarViewController!
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, UUID>!
    
    private var bread: Bread
    private var model: WordItemModel
    private var editModel: WordItemModel
    
    private var isItemsPanned: [Bool] = []
    private var selectedFilters: Set<Int> = []
    private var editingFilterIndex: Int?
    
    private var highlightedItemIndexForEditing: Int?

    private var currentContentOffset: CGPoint = .zero
    private var sectionTitleViewHeight: CGFloat = 0
    
    private var editingFilterColor: UIColor? {
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
        self.model = WordItemModel(bread: bread)
        self.editModel = WordItemModel(bread: bread)
        super.init(nibName: nil, bundle: nil)
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
            toolbarViewController.select(selectedFilters)
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
            editModel = WordItemModel(model)
            dataSource.reconfigure(editModel.idsHavingFilter(), animatingDifferences: true)
            editContentButtonItem.isEnabled = false
            toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
            return
        }
        
        model = WordItemModel(editModel)
        model.updateBreadFilterIndexes()

        dataSource.reconfigure(model.idsHavingFilter(), animatingDifferences: true)
        editContentButtonItem.isEnabled = true
        
        editingFilterIndex = nil
        highlightedItemIndexForEditing = nil
        
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
    }
    
    @objc
    private func orientationDidChange(_ notification: Notification) {
        sectionTitleViewHeight = bread.title?.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font) ?? 0
        updateNaviTitleViewShowingIfNeeded()
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
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCell, UUID> {
            [weak self] cell, indexPath, id in
            guard let self = self else {
                return
            }
            
            if self.isEditing {
                guard let item = self.editModel.item(forKey: id) else {
                    return
                }
                cell.label.text = item.word
                cell.overlayView.backgroundColor = item.filterColor?.withAlphaComponent(0.5) ?? .clear
                return
            }
            
            guard let item = self.model.item(forKey: id) else {
                return
            }
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
        
        dataSource = UICollectionViewDiffableDataSource<Section, UUID>(collectionView: collectionView) { collectionView, indexPath, id in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            return self?.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }
        
        applyNewData(model.ids())
    }
    
    private func applyNewData(_ identifiers: [UUID]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(identifiers, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if isEditing {
            highlightedItemIndexForEditing = indexPath.item
            updateEditModelIfNeeded(forID: id)
            return
        }
        
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        if let colorIndex = model.ColorIndex(forKey: id),
           selectedFilters.contains(colorIndex) {
            model.togglePeek(forKey: id)
            dataSource.reconfigure([id], animatingDifferences: true)
        }
    }
    
    private func updateEditModelIfNeeded(at index: Int) {
        guard let id = dataSource.itemIdentifier(for: IndexPath(row: index, section: 0)) else {
            return
        }
        updateEditModelIfNeeded(forID: id)
    }
    
    private func updateEditModelIfNeeded(forID id: UUID) {
        guard isEditing else {
            return
        }
        
        if editingFilterColor == nil { // 편집용 필터 선택되지 않음
            if editModel.hasFilter(forKey: id) {
                editModel.removeFilter(forKey: id)
                dataSource.reconfigure([id], animatingDifferences: true)
            }
            return
        }
        
        // 편집용 필터 선택됨
        if editModel.item(forKey: id)?.filterColor == editingFilterColor {
            editModel.removeFilter(forKey: id)
            dataSource.reconfigure([id], animatingDifferences: true)
            return
        }
        
        if let editingFilterIndex = editingFilterIndex {
            editModel.setFilter(forKey: id,
                                to: editingFilterColor,
                                isFiltered: selectedFilters.contains(editingFilterIndex))
            dataSource.reconfigure([id], animatingDifferences: true)
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
        updateFilter(index, setFilter: true)
    }
    
    private func filterDeselected(at index: Int) {
        if isEditing {
            editingFilterIndex = nil
            return
        }
        selectedFilters.remove(index)
        updateFilter(index, setFilter: false)
    }
    
    private func updateFilter(_ filterValue: Int, setFilter isFiltered: Bool) {
        let updatedKeys = model.updateFilterOfItems(using: filterValue, isFiltered: isFiltered)
        dataSource.reconfigure(updatedKeys, animatingDifferences: true)
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
            isItemsPanned = Array(repeating: false, count: editModel.count)
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
                updateEditModelIfNeeded(at: index)
            }
        default:
            break
        }
    }
}

// MARK: - Alert
extension BreadViewController {
    @objc
    private func didTapSupplementaryTitleView(_ sender: UITapGestureRecognizer) {
        let titleEditAlert = UIAlertController(title: "제목 변경", message: nil, preferredStyle: .alert)
        titleEditAlert.addTextField { [weak self] textField in
            textField.clearButtonMode = .always
            textField.returnKeyType = .done
            textField.text = self?.bread.title
        }
        
        titleEditAlert.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel))
        titleEditAlert.addAction(UIAlertAction(title: LocalizingHelper.done, style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let inputText = titleEditAlert.textFields?.first?.text {
                self.bread.updateTitle(inputText)
                BreadDAO.default.save()
                self.updateNaviTitleView(using: inputText)
            }
        })
        
        present(titleEditAlert, animated: true)
    }
    
    private func updateNaviTitleView(using title: String) {
        naviTitleView.text = bread.title
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.main])
        dataSource.apply(snapshot)
    }
}

// MARK: - present
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
    
    private func didCompleteContentEditing(_ newContent: String) {
        let newContent = newContent.trimmingCharacters(in: [" "])
        guard bread.content != newContent else { return }

        model.updateContent(newContent)
        applyNewData(model.ids())
        
        toolbarViewController.deselectAllFilter()
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
        selectedFilters.removeAll()
    }
}

extension UICollectionViewDiffableDataSource {
    func reconfigure(_ identifiers: [ItemIdentifierType], animatingDifferences: Bool = false) {
        var snapshot = snapshot()
        if #available(iOS 15.0, *) {
            snapshot.reconfigureItems(identifiers)
            apply(snapshot, animatingDifferences: animatingDifferences)
        } else {
            snapshot.reloadItems(identifiers)
            apply(snapshot, animatingDifferences: false)
        }
    }
}
