//
//  BasicAlert.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/16.
//

import UIKit

final class BasicAlert {
    static func makeConfirmAlert(title: String?, message: String?, confirmCallback: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizingHelper.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: LocalizingHelper.confirm, style: .default, handler: confirmCallback))
        return alert
    }
    
    static func makeErrorAlert(message: String?, completionHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: LocalizingHelper.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizingHelper.confirm, style: .default, handler: completionHandler))
        return alert
    }
}
