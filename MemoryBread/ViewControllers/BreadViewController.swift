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
    
    var bread: Bread?
    private var wordItems: [WordItem]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bread = Bread(touch: Date.now,
                      directoryName: "임시 폴더",
                      title: "임시 타이틀",
                      content: Page.sampleContent,
                      separatedContent: Page.sampleSeparatedContent,
                      filterIndexes: Page.sampleFilterIndex)
        wordItems = popluateData(from: bread)
        
        
        configureHierarchy()
        configureDataSource()
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
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(isFiltered)
        }
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.identifier == rhs.identifier
            && lhs.isFiltered == rhs.isFiltered
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCell, WordItem> { cell, indexPath, item in
            cell.label.text = item.word
            if item.isFiltered {
                cell.backgroundColor = item.filterColor
                cell.label.textColor = item.filterColor
            } else {
                cell.backgroundColor = .clear
                cell.label.textColor = .black
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, WordItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        reloadDataSource()
    }
    
    private func reloadDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, WordItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(wordItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func filterSelected(at index: Int, isSelected: Bool) {
        bread?.filterIndexes?[index].forEach { wordItems[$0].isFiltered = isSelected }
        reloadDataSource()
    }
}

// MARK: - Data Modifier
extension BreadViewController {
    private func popluateData(from bread: Bread?) -> [WordItem] {
        guard let separatedContent = bread?.separatedContent,
              let filterIndexes = bread?.filterIndexes else {
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
}

// MARK: - UICollectionView Delegate
extension BreadViewController: UICollectionViewDelegate {
    
}

// MARK: - ColorFilterToolbar Delegate
extension BreadViewController: ColorFilterToolbarDelegate {
    func colorFilterToolbar(didSelectColorIndex index: Int) {
        filterSelected(at: index, isSelected: true)
    }
    
    func colorFilterToolbar(didDeselectColorIndex index: Int) {
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
