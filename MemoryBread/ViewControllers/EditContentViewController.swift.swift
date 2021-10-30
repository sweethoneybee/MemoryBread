//
//  EditContentViewController.swift.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/30.
//

import UIKit
import SnapKit

final class EditContentViewController: UIViewController {
    
    var content: String
    var didCompleteEditing: ((String) -> (Void))?
    
    private var contentTextField: UITextView!
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    init(content: String) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        configureHierarchy()
        configureNavigation()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        contentTextField.resignFirstResponder()
    }
}

// MARK: - Configure Views
extension EditContentViewController {
    private func configureHierarchy() {
        contentTextField = UITextView().then {
            $0.text = content
        }
        
        view.addSubview(contentTextField)
        configureLayouts()
    }
    
    private func configureLayouts() {
        contentTextField.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
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
extension EditContentViewController: UITextViewDelegate {
    @objc func cancelEditing() {
        dismiss(animated: true)
    }
    
    @objc
    private func completeEditing() {
        didCompleteEditing?(contentTextField.text)
        dismiss(animated: true)
    }
}
