//
//  EditContentViewController.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/30.
//

import UIKit
import SnapKit

final class EditContentViewController: UIViewController {
    struct UIConstants {
        static let contentInset: CGFloat = 20
    }
    
    var content: String
    var didCompleteEditing: ((String) -> (Void))?
    
    private var contentTextField: UITextView!
    private var bottomConstraint: Constraint?
    private var keyboardShown = false
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
            $0.contentInset = UIEdgeInsets(top: 0, left: UIConstants.contentInset, bottom: 0, right: UIConstants.contentInset)
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
        let cancelItem = UIBarButtonItem(title: "취소",
                                         style: .plain,
                                         target: self,
                                         action: #selector(cancelEditing))
        navigationItem.leftBarButtonItem = cancelItem
        
        let doneItem = UIBarButtonItem(title: "완료",
                                       style: .plain,
                                       target: self,
                                       action: #selector(completeEditing))
        navigationItem.rightBarButtonItem = doneItem
        
        navigationItem.title = "내용 수정"
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

// MARK: - Keyboard Show, Hide
extension EditContentViewController {
    // refer to sendbird SDK example
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrameEndRect = keyboardFrameEnd.cgRectValue
        let keyboardHeightWithoutSafeLayoutInset = keyboardFrameEndRect.height - view.safeAreaInsets.bottom
        if !keyboardShown {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                self.bottomConstraint?.update(offset: -keyboardHeightWithoutSafeLayoutInset)
                self.view.layoutIfNeeded()
            })
        }
        keyboardShown = true
    }
    
    @objc
    private func keyboardWillHide(_ notification: Notification) {
        if keyboardShown {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                self.bottomConstraint?.update(offset: 0)
                self.view.layoutIfNeeded()
            })
        }
        keyboardShown = false
    }
}
