//
//  EditContentViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/30.
//

import UIKit
import SnapKit
import Combine

final class EditContentViewController: UIViewController {
    struct UIConstants {
        static let contentInset: CGFloat = 20
    }
    
    var didCompleteEditing: ((String) -> (Void))?
    
    private var content: String
    private var contentTextField: UITextView!
    private var bottomConstraint: Constraint?
    private var keyboardShown = false
    
    private var cancellableBag: [AnyCancellable] = []
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(content: String) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureHierarchy()
        configureNavigation()
        
        
        let keyboardShownCancellable = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .sink { [weak self] notification in
                guard let self = self,
                      let keyboardFrameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
                let keyboardFrameEndRect = keyboardFrameEnd.cgRectValue
                let keyboardHeightWithoutSafeLayoutInset = keyboardFrameEndRect.height - self.view.safeAreaInsets.bottom
                if !(self.keyboardShown) {
                    UIView.animate(withDuration: 0.3,
                                   delay: 0,
                                   options: .curveEaseInOut,
                                   animations: {
                        self.bottomConstraint?.update(offset: -keyboardHeightWithoutSafeLayoutInset)
                        self.view.layoutIfNeeded()
                    })
                }
                self.keyboardShown = true
            }
        
        let keyboardHideCancellable = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification, object: nil)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if self.keyboardShown {
                    UIView.animate(withDuration: 0.3,
                                   delay: 0,
                                   options: .curveEaseInOut,
                                   animations: {
                        self.bottomConstraint?.update(offset: 0)
                        self.view.layoutIfNeeded()
                    })
                }
                self.keyboardShown = false
            }
        
        cancellableBag.append(keyboardShownCancellable)
        cancellableBag.append(keyboardHideCancellable)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        contentTextField.resignFirstResponder()
    }
}

// MARK: - Configure Views
extension EditContentViewController {
    private func configureHierarchy() {
        contentTextField = UITextView().then {
            $0.adjustsFontForContentSizeCategory = true
            $0.font = .preferredFont(forTextStyle: .body)
            $0.text = content
            $0.textContainerInset = UIEdgeInsets(
                top: 8, // default value
                left: UIConstants.contentInset,
                bottom: 8,
                right: UIConstants.contentInset
            )
            $0.keyboardDismissMode = .interactive
        }
        
        view.addSubview(contentTextField)
        configureLayouts()
    }
    
    private func configureLayouts() {
        contentTextField.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            bottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
        }
    }
    
    private func configureNavigation() {
        let cancelItem = UIBarButtonItem(title: LocalizingHelper.cancel,
                                         style: .plain,
                                         target: self,
                                         action: #selector(cancelEditing))
        navigationItem.leftBarButtonItem = cancelItem
        
        let doneItem = UIBarButtonItem(title: LocalizingHelper.done,
                                       style: .plain,
                                       target: self,
                                       action: #selector(completeEditing))
        navigationItem.rightBarButtonItem = doneItem
        
        navigationItem.title = LocalizingHelper.editContent
    }
}

// MARK: - objc
extension EditContentViewController {
    @objc func cancelEditing() {
        dismiss(animated: true)
    }
    
    @objc
    private func completeEditing() {
        didCompleteEditing?(contentTextField.text)
        dismiss(animated: true)
    }
}
