//
//  BasicAlert.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/16.
//

import UIKit

final class BasicAlert {
    
    typealias BasicAlertCompletionHandler = ((UIAlertAction) -> ())
    
    static func makeCancelAndConfirmAlert(title: String?, message: String?, completionHandler: BasicAlertCompletionHandler? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: LocalizingHelper.confirm, style: .default, handler: completionHandler))
        return alert
    }
    
    static func makeErrorAlert(message: String?, completionHandler: BasicAlertCompletionHandler? = nil) -> UIAlertController {
        let alert = UIAlertController(title: LocalizingHelper.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizingHelper.confirm, style: .default, handler: completionHandler))
        return alert
    }
    
    static func makeConfirmAlert(title: String?, message: String?, completionHandler: BasicAlertCompletionHandler? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizingHelper.confirm, style: .default, handler: completionHandler))
        return alert
    }
    
    static func makeDestructiveAlertSheet(alertTitle: String? = nil, destructiveTitle: String? = nil, completionHandler: BasicAlertCompletionHandler? = nil) -> UIAlertController {
        let actionSheet = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: destructiveTitle, style: .destructive, handler: completionHandler))
        actionSheet.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel))
        return actionSheet
    }
}

