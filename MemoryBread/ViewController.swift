//
//  ViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/24.
//

import UIKit
import Then
import SnapKit

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
    var content: String
}

class ViewController: UIViewController {

    lazy var sampleContent = popluateData()
    enum Section {
        case main
    }
    
    struct Item: Hashable {
        let identifier = UUID()
        let word: String
        var isSelected = false
        
        func populateWithNewId() -> Item {
            return Item(word: word, isSelected: isSelected)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func ==(lhs: Item, rhs: Item) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var collectionView: UICollectionView!
    var toolBar: HorizontalScrollToolBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        collectionView.delegate = self
    }
}

extension ViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50),
                                              heightDimension: .estimated(50))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
//        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(50))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}

extension ViewController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        configureToolbar()
        
        configureLayouts()
    }
    
    private func configureToolbar() {
        toolBar = HorizontalScrollToolBar()
        for _ in 0..<10 {
            let view1 = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)).then { $0.backgroundColor = .red }
            toolBar.appendSubview(view1)
        }
        
        let view1 = UIView().then { $0.backgroundColor = .blue }
        let view2 = UIView().then { $0.backgroundColor = .green }
        let view3 = UIView().then { $0.backgroundColor = .darkGray }
        toolBar.appendSubviews([view1, view2, view3])
        view.addSubview(toolBar)
    }
    
    private func configureLayouts() {
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(100)
            make.width.equalTo(view)
            make.bottom.equalTo(view.snp.bottom)
            make.centerX.equalToSuperview()
        }
        
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<TextCell, Item> { cell, indexPath, item in
            cell.label.text = item.word
            cell.label.textAlignment = .center
            cell.didSelected(item.isSelected)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(sampleContent)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func reloadDataSource(with item: Item) {
        var snapshot = dataSource.snapshot()
        snapshot.insertItems([item.populateWithNewId()], afterItem: item)
        snapshot.deleteItems([item])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension ViewController {
    private func popluateData() -> [Item] {
        return Page.sampleContent
            .components(separatedBy: ["\n", " "])
            .map { Item(word: $0) }
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if var item = dataSource.itemIdentifier(for: indexPath) {
            sampleContent[indexPath.row].isSelected.toggle()
            item.isSelected.toggle()
            reloadDataSource(with: item)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

