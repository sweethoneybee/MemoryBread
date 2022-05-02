//
//  MoveBreadViewControllerPresentable.swift
//  MemoryBread
//
//  Created by 정성훈 on 2022/03/05.
//

import UIKit
import CoreData

protocol MoveBreadViewControllerPresentable where Self: UIViewController {
    var sourceFolderObjectID: NSManagedObjectID? { get }
    func presentMoveBreadViewControllerWith(coreDataStack: CoreDataStack, targetBreadObjectIDs: [NSManagedObjectID])
}

extension MoveBreadViewControllerPresentable {
    func presentMoveBreadViewControllerWith(coreDataStack: CoreDataStack, targetBreadObjectIDs: [NSManagedObjectID]) {
        let model = MoveBreadModel(
            coreDataStack: coreDataStack,
            selectedBreadObjectIDs: targetBreadObjectIDs,
            shouldDisabledFolderObjectID: sourceFolderObjectID
        )
        let optimizer = MoveBreadViewOptimizer()
        let mbvc = MoveBreadViewController(
            model: model,
            optimizer: optimizer,
            moveDoneHandler: { [weak self] in
            self?.setEditing(false, animated: true)
        })
        let nvc = UINavigationController(rootViewController: mbvc)
        
        present(nvc, animated: true)
    }
}
