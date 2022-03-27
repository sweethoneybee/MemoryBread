//
//  SettingViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/25.
//

import UIKit

final class AdjustWordsSizeViewController: UIViewController {
    
    private let oldWordSize: WordSize
    private var currentWordSize: WordSize {
        didSet {
            exampleLabel.font = exampleLabel.font.withSize(currentWordSize.fontSize)
            WordCell.setLabelFont(using: self.currentWordSize)
        }
    }
    
    private let wordSizeCalculator = WordSizeCalculator()
    private let fontSizeSlider = UISlider(frame: .zero).then {
        $0.minimumValueImage = UIImage(systemName: "textformat.size.smaller")
        $0.maximumValueImage = UIImage(systemName: "textformat.size.larger")
        $0.minimumTrackTintColor = .systemGray
        $0.maximumTrackTintColor = .systemGray
        $0.tintColor = UITraitCollection.current.userInterfaceStyle == .light ? .black : .white
    }
    
    private let exampleLabel = UILabel(frame: .zero).then {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = WordCell.getLabelFont()
        $0.text = LocalizingHelper.pangram
    }
    
    private let helpMessageLabel = UILabel(frame: .zero).then {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.text = LocalizingHelper.helpMessageForAdjustingWordsSize
    }
    
    var didFinishAdjustingHandler: (() -> Void)?
    
    // MARK: - Methods
    init(currentWordSize: WordSize) {
        self.currentWordSize = currentWordSize
        self.oldWordSize = currentWordSize
        super.init(nibName: nil, bundle: nil)
        fontSizeSlider.setValue(currentWordSize.sliderValue, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("\(#function) not implemented.")
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = LocalizingHelper.adjustWordsSize
        navigationItem.largeTitleDisplayMode = .never
        setViews()
        
        fontSizeSlider.addAction(UIAction(handler: { [weak self] action in
            guard let self = self,
                  let slider = action.sender as? UISlider else {
                return
            }
            
            let fontSize = self.wordSizeCalculator.wordSize(of: slider.value)
            slider.setValue(fontSize.sliderValue, animated: false)
            if fontSize != self.currentWordSize {
                self.currentWordSize = fontSize
            }
        }), for: .valueChanged)
    }
    
    private func setViews() {
        view.addSubview(fontSizeSlider)
        fontSizeSlider.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(50)
        }
        
        view.addSubview(helpMessageLabel)
        helpMessageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.bottom.equalTo(fontSizeSlider.snp.top).offset(-10)
        }
        
        view.addSubview(exampleLabel)
        exampleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updateUI(to: newCollection.userInterfaceStyle)
    }
    
    private func updateUI(to newUserInterfaceStyle: UIUserInterfaceStyle) {
        switch newUserInterfaceStyle {
        case .light:
            fontSizeSlider.tintColor = .black
        case .dark:
            fontSizeSlider.tintColor = .white
        case .unspecified:
            fontSizeSlider.tintColor = .black
        @unknown default:
            fontSizeSlider.tintColor = .black
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if oldWordSize != currentWordSize {
            didFinishAdjustingHandler?()            
        }
    }
}
