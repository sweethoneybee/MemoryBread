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
    var trashFolderObjectID: NSManagedObjectID { get }
    
    func presentMoveBreadViewControllerWith(context: NSManagedObjectContext, targetBreadObjectIDs: [NSManagedObjectID])
}

extension MoveBreadViewControllerPresentable {
    func presentMoveBreadViewControllerWith(context: NSManagedObjectContext, targetBreadObjectIDs: [NSManagedObjectID]) {
        let model = MoveBreadModel(
            context: context,
            selectedBreadObjectIDs: targetBreadObjectIDs,
            shouldDisabledFolderObjectID: sourceFolderObjectID
        )
        let viewModel = MoveBreadViewModel()
        let mbvc = MoveBreadViewController(
            model: model,
            viewModel: viewModel,
            moveDoneHandler: { [weak self] in
            self?.setEditing(false, animated: true)
        })
        let nvc = UINavigationController(rootViewController: mbvc)
        
        present(nvc, animated: true)
    }
}
