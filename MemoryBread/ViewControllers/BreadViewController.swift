//
//  BreadViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit
import CoreData

final class BreadViewController: UIViewController {
    enum Section {
        case main
    }
    
    // MARK: - Constants
    struct UIConstants {
        static let edgeInset: CGFloat = 20
        static let wordItemSpacing: CGFloat = 5
        static let lineSpacing: CGFloat = 7
        static let backButtonOffset: CGFloat = -10
    }
    
    private var collectionViewContentWidth: CGFloat {
        return floor(view.safeAreaLayoutGuide.layoutFrame.width - UIConstants.edgeInset * 2)
    }
    
    // MARK: - Views
    private var naviTitleView: ScrollableTitleView!
    private var editContentButtonItem: UIBarButtonItem!
    private var toolbarViewController: ColorFilterToolbarViewController!
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, UUID>!
    
    private var previousWord: String? = nil
    
    // MARK: - Alert Action
    private weak var editDoneAction: UIAlertAction?
    
    // MARK: - States
    private var panGestureCheckerOfItems: [Bool] = []
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
    
    // MARK: - Models
    private let viewContext: NSManagedObjectContext
    private let bread: Bread
    private let wordPainter: WordPainter
    
    // MARK: - Life Cycle
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(context: NSManagedObjectContext, bread: Bread) {
        self.viewContext = context
        self.bread = bread
        self.wordPainter = WordPainter(bread: bread)
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
        
        sectionTitleViewHeight = bread.title.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font)
        
        toolbarViewController.select(bread.selectedFilters)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let selectedFiltersArray = Array(selectedFilters)
        let latestSelectedFilters = bread.selectedFilters
        if latestSelectedFilters != selectedFiltersArray {
            bread.selectedFilters = Array(selectedFilters)
            viewContext.saveIfNeeded()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        toolbarViewController.setEditing(editing, animated: animated)
        
        if editing {
            dataSource.reconfigure(wordPainter.idsHavingFilter(), animatingDifferences: true)
            editContentButtonItem.isEnabled = false
            toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
            return
        }
        
        wordPainter.makeFilterIndexesUpToDate()
        viewContext.saveIfNeeded()

        dataSource.reconfigure(wordPainter.idsHavingFilter(), animatingDifferences: true)
        editContentButtonItem.isEnabled = true
        
        editingFilterIndex = nil
        highlightedItemIndexForEditing = nil
        
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previousWord = nil
    }
    
    @objc
    private func orientationDidChange(_ notification: Notification) {
        sectionTitleViewHeight = bread.title.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font)
        updateNaviTitleViewShowingIfNeeded()
    }
}

// MARK: - Configure Views
extension BreadViewController {
    private func createLayout() -> UICollectionViewLayout {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumInteritemSpacing = UIConstants.wordItemSpacing
        layout.minimumLineSpacing = UIConstants.lineSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: UIConstants.edgeInset, bottom: 0, right: UIConstants.edgeInset)
        return layout
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .breadBody
        collectionView.register(SupplemantaryTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SupplemantaryTitleView.reuseIdentifier)
        collectionView.alwaysBounceVertical = true
        
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
        editContentButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(showEditContentViewController)
        )
        
        let adjustWordsSizeButtonItem = UIBarButtonItem(
            title: LocalizingHelper.adjustWordsSize,
            image: UIImage(systemName: "textformat.size"),
            primaryAction: UIAction(handler: { [weak self] _ in
                let adjustVC = AdjustWordsSizeViewController(currentWordSize: WordCell.getLabelFont().makeWordSize())
                adjustVC.didFinishAdjustingHandler = { [weak self] in
                    self?.collectionView.reloadData()
                    self?.collectionView.collectionViewLayout.invalidateLayout()
                }
                self?.navigationController?.pushViewController(adjustVC, animated: true)
            }),
            menu: nil
        )
        navigationItem.rightBarButtonItems = [editButtonItem, editContentButtonItem, adjustWordsSizeButtonItem]
        navigationItem.largeTitleDisplayMode = .never

        naviTitleView = ScrollableTitleView(frame: .zero).then {
            $0.text = bread.title
        }
    }
}

extension BreadViewController: UICollectionViewDelegateFlowLayout {
    private func wordCellSizeWith(word: String, attributes: [NSAttributedString.Key: Any]?) -> CGSize {
        let fractionalWordSize = word.size(withAttributes: attributes)
        let wordSize = CGSize(width: ceil(fractionalWordSize.width), height: ceil(fractionalWordSize.height))
        let wordWidth = wordSize.width
        
        if wordWidth <= collectionViewContentWidth {
            return wordSize
        }
        
        let heightMultiplier = ceil(wordWidth / collectionViewContentWidth)
        return CGSize(width: collectionViewContentWidth, height: wordSize.height * heightMultiplier)
    }
    
    private func newLineWordCell(attributes: [NSAttributedString.Key: Any]?) -> CGSize {
        if previousWord == "\n" {
            return CGSize(width: collectionViewContentWidth, height: UIConstants.lineSpacing * 2)
        }
        return CGSize(width: collectionViewContentWidth, height: UIConstants.lineSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let id = dataSource.itemIdentifier(for: indexPath),
           let item = wordPainter.item(forKey: id) {
            
            let att = [NSAttributedString.Key.font: WordCell.getLabelFont()]
            let size: CGSize
            if item.word == "\n" {
                size = newLineWordCell(attributes: att)
            } else {
                size = wordCellSizeWith(word: item.word, attributes: att)
            }
            
            previousWord = item.word
            return size
        }
        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let calculatedHeight = bread.title.height(withConstraintWidth: collectionViewContentWidth, font: SupplemantaryTitleView.font) + SupplemantaryTitleView.UIConstants.bottomInset
        return CGSize(width: collectionViewContentWidth, height: calculatedHeight)
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
            
            let item = self.wordPainter.item(forKey: id)
            if let item = item {
                cell.configure(using: item, isEditing: self.isEditing)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, UUID>(collectionView: collectionView) { collectionView, indexPath, id in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: id)
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) in
            guard let self = self,
                  let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SupplemantaryTitleView.reuseIdentifier, for: indexPath) as? SupplemantaryTitleView else {
                return nil
            }
            
            supplementaryView.configure(using: self.bread.title)
            supplementaryView.delegate = self
            return supplementaryView
        }
        
        applyNewSnapshot(using: wordPainter.ids())
    }
    
    private func applyNewSnapshot(using identifiers: [UUID]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(identifiers, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        let item = wordPainter.item(forKey: id)
        guard item?.word != "\n" else {
            return
        }
        
        if isEditing {
            highlightedItemIndexForEditing = indexPath.item
            updateEditModelIfNeeded(forID: id)
            return
        }
        
        if let colorIndex = FilterColor.colorIndex(for: item?.filterColor),
           selectedFilters.contains(colorIndex) {
            wordPainter.togglePeekingOfItem(forKey: id)
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
        
        guard wordPainter.item(forKey: id)?.word != "\n" else {
            return
        }
        
        if editingFilterColor == nil { // 편집용 필터 선택되지 않음
            if wordPainter.itemHasFilter(forKey: id) {
                wordPainter.removeFilterOfItem(forKey: id)
                dataSource.reconfigure([id], animatingDifferences: true)
            }
            return
        }
        
        // 편집용 필터 선택됨
        if wordPainter.item(forKey: id)?.filterColor == editingFilterColor {
            wordPainter.removeFilterOfItem(forKey: id)
            dataSource.reconfigure([id], animatingDifferences: true)
            return
        }
        
        if let editingFilterIndex = editingFilterIndex {
            wordPainter.setFilterOfItem(
                forKey: id,
                to: editingFilterColor,
                isFiltered: selectedFilters.contains(editingFilterIndex)
            )
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
        let updatedKeys = wordPainter.updateFilterOfItems(using: filterValue, isFiltered: isFiltered)
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
            panGestureCheckerOfItems = Array(repeating: false, count: wordPainter.itemCount)
            if let justHighlighted = highlightedItemIndexForEditing {
                panGestureCheckerOfItems[justHighlighted] = true
                highlightedItemIndexForEditing = nil
            }
        case .changed:
            let touchedPoint = sender.location(in: collectionView)
            if let index = collectionView.indexPathForItem(at: touchedPoint)?.item,
               index < panGestureCheckerOfItems.count, // check index out of range
               panGestureCheckerOfItems[index] == false {
                panGestureCheckerOfItems[index] = true
                updateEditModelIfNeeded(at: index)
            }
        default:
            break
        }
    }
}

// MARK: - SupplemantaryTitleViewDelegate
extension BreadViewController: SupplemantaryTitleViewDelegate {
    func didTapTitleView(_ view: UICollectionReusableView) {
        let titleEditAlert = UIAlertController(title: LocalizingHelper.changingTheTitle, message: nil, preferredStyle: .alert)
        titleEditAlert.addTextField { [weak self] textField in
            textField.clearButtonMode = .always
            textField.returnKeyType = .done
            textField.text = self?.bread.title
            
            if let self = self {
                NotificationCenter.default.addObserver(self, selector: #selector(self.textDidChange(_:)), name: UITextField.textDidChangeNotification, object: textField)
            }
        }
        
        titleEditAlert.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel))
        
        let doneAction = UIAlertAction(title: LocalizingHelper.done, style: .default) { [weak self, weak titleEditAlert] _ in
            guard let self = self else { return }
            NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: titleEditAlert?.textFields?.first)
            if let inputText = titleEditAlert?.textFields?.first?.text?.trimmingCharacters(in: [" "]) {
                self.bread.updateTitle(inputText)
                self.viewContext.saveIfNeeded()
                self.updateNaviTitleView(using: inputText)
            }
        }
        editDoneAction = doneAction
        titleEditAlert.addAction(doneAction)
        
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
        guard isEditing == false else {
            return
        }
        
        let editContentViewController = EditContentViewController(content: bread.content)
        editContentViewController.didCompleteEditing = didCompleteContentEditing(_:)
        let nvc = UINavigationController(rootViewController: editContentViewController)
        navigationController?.present(nvc, animated: true)
    }
    
    private func didCompleteContentEditing(_ newContent: String) {
        let newContent = newContent.trimmingCharacters(in: [" "])
        guard bread.content != newContent else { return }

        bread.updateContent(with: newContent)
        viewContext.saveIfNeeded()
        
        wordPainter.refreshItems()
        
        applyNewSnapshot(using: wordPainter.ids())
        
        toolbarViewController.deselectAllFilter()
        toolbarViewController.showNumberOfFilterIndexes(using: bread.filterIndexes)
        selectedFilters.removeAll()
    }
}

// MARK: - TextFieldAlertActionEnabling
extension BreadViewController: TextFieldAlertActionEnabling {
    var alertAction: UIAlertAction? {
        editDoneAction
    }
    
    @objc
    private func textDidChange(_ notification: Notification) {
        enableAlertActionByTextCount(notification)
    }
}
