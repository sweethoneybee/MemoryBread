//
//  BasicAlert.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/16.
//

import UIKit

final class BasicAlert {
    
    typealias BasicAlertCompletionHandler = ((UIAlertAction) -> ())
    
    static func makeCancelAndConfirmAlert(
        title: String?,
        message: String?,
        confirmActionTitle: String? = LocalizingHelper.confirm,
        cancelHandler: BasicAlertCompletionHandler? = nil,
        completionHandler: BasicAlertCompletionHandler? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel, handler: cancelHandler))
        alert.addAction(UIAlertAction(title: confirmActionTitle, style: .default, handler: completionHandler))
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
    
    static func makeDestructiveAlert(
        alertTitle: String? = nil,
        message: String? = nil,
        destructiveTitle: String? = nil,
        completionHandler: BasicAlertCompletionHandler? = nil,
        cancelHandler: BasicAlertCompletionHandler? = nil
    ) -> UIAlertController {
        let alertStyle: UIAlertController.Style
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = .alert
        } else {
            alertStyle = .actionSheet
        }
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: alertStyle)
        alert.addAction(UIAlertAction(title: destructiveTitle, style: .destructive, handler: completionHandler))
        alert.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel, handler: cancelHandler))
        return alert
    }
}

