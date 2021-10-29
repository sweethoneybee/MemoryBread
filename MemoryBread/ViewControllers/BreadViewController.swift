//
//  BreadViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/29.
//

import UIKit
import SnapKit

class BreadViewController: UIViewController {
    var toolbarViewController: ColorFilterToolbarViewController!
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, WordItem>!
    
    var bread: Bread
    private var wordItems: [WordItem]!
    private var editingItems: [WordItem]?
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
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        configureLayouts()
    }
    
    private func configureLayouts() {
        
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
        navigationItem.rightBarButtonItems = [editButtonItem]
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

// MARK: - Diffable Data Source
extension BreadViewController {
    enum Section {
        case main
    }
    
    struct WordItem: Hashable {
        let identifier = UUID()
        let word: String
        var isFiltered: Bool = false
        var filterColor: UIColor?
  
        init(word: String) {
            self.word = word
        }
        
        init(_ item: Self) {
            self.word = item.word
            self.filterColor = item.filterColor
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(isFiltered)
            hasher.combine(filterColor)
        }
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.identifier == rhs.identifier
            && lhs.isFiltered == rhs.isFiltered
            && lhs.filterColor == rhs.filterColor
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
                cell.backgroundColor = item.filterColor
                cell.label.textColor = item.filterColor
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
    
    func filterSelected(at index: Int, isSelected: Bool) {
        bread.filterIndexes?[index].forEach { wordItems[$0].isFiltered = isSelected }
        reloadDataSource(with: wordItems)
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
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if isEditing,
        let editingFilter = selectedFilterWithEditing {
            let index = indexPath.item
            editingItems?[index].filterColor = FilterColor(rawValue: editingFilter)?.color()
            reloadDataSource(with: editingItems)
        }
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
    }
    
    func colorFilterToolbar(didDeselectColorIndex index: Int) {
        if isEditing {
            selectedFilterWithEditing = nil
            return
        }
        filterSelected(at: index, isSelected: false)
    }
}

struct Page {
    static let sampleContent =
"""
근로계약에서 정한 휴식시간이나 대기시간이 근로시간에 속하는지 휴게시간에 속하는지는 특정업종이나
업무의 종류에 따라 일률적으로 판단할 것이 아니다. 이는 근로계약의 내용이나 해당 사업장에 적용되는
취업규칙과 단체협약의 규정, 근로자가 제공하는 업무의 내용과 해당 사업장의 구체적 업무 방식, 휴게 중인
근로자에 대한 사용자의 간섭이나 감독여부, 자유롭게 이용할 수 있는 휴게장소의 구비 여부, 그 밖에 근로자의
실질적 휴식이 방해되었다거나 사용자의 지휘, 감독을 인정할 만한 사정이 있는지와 그 정도 등 여러 사정을
종합하여 개별사안에 따라 구체적으로 판단하여야 한다.
근로계약에서 정한 휴식시간이나 대기시간이 근로시간에 속하는지 휴게시간에 속하는지는 특정업종이나
업무의 종류에 따라 일률적으로 판단할 것이 아니다. 이는 근로계약의 내용이나 해당 사업장에 적용되는
취업규칙과 단체협약의 규정, 근로자가 제공하는 업무의 내용과 해당 사업장의 구체적 업무 방식, 휴게 중인
근로자에 대한 사용자의 간섭이나 감독여부, 자유롭게 이용할 수 있는 휴게장소의 구비 여부, 그 밖에 근로자의
실질적 휴식이 방해되었다거나 사용자의 지휘, 감독을 인정할 만한 사정이 있는지와 그 정도 등 여러 사정을
종합하여 개별사안에 따라 구체적으로 판단하여야 한다.
"""
    static var sampleSeparatedContent: [String] {
        Page.sampleContent.components(separatedBy: ["\n", " "])
    }
    
    static var sampleFilterIndex: [[Int]] {
        [
            [0, 1, 3, 5, 7, 9],
            [15, 16, 17],
            [20, 21, 25],
            [28],
        ]
    }
    var content: String
}
