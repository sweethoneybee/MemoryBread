//
//  TextFieldAlertActionEnabling.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/04.
//

import UIKit

protocol TextFieldAlertActionEnabling where Self: UIViewController {
    var alertAction: UIAlertAction? { get }
    func enableAlertActionByTextCount(_ notification: Notification)
}

extension TextFieldAlertActionEnabling {
    func enableAlertActionByTextCount(_ notification: Notification) {
        guard let textField = notification.object as? UITextField,
              let trimmedText = textField.text?.trimmingCharacters(in: [" "]) else {
                  return
              }
        
        alertAction?.isEnabled = (trimmedText.count > 0)
    }
}
