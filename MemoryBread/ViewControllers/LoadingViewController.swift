//
//  LoadingViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/30.
//

import UIKit

final class LoadingView: UIView {
    struct State {
        var isLoading: Bool
    }
    
    // MARK: - Views
    private let indicator = UIActivityIndicatorView(style: .large).then {
        $0.hidesWhenStopped = true
        $0.tintColor = .red
    }
    
    // MARK: - Set
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .black.withAlphaComponent(0.2)
        addSubview(indicator)
        
        // MARK: - layouts
        indicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func set(state: State) {
        if state.isLoading {
            indicator.startAnimating()
            return
        }
        
        indicator.stopAnimating()
    }
}

final class LoadingViewController: UIViewController {
    // MARK: - View
    private lazy var loadingView = LoadingView()
    
    // MARK: - LifeCycle
    override func loadView() {
        self.view = loadingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingView.set(state: .init(isLoading: true))
    }
    
    func set(state: LoadingView.State) {
        loadingView.set(state: state)
        if !state.isLoading {
            dismiss(animated: false)
        }
    }
}
