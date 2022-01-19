//
//  SceneDelegate.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

//        let breadListViewController = BreadListViewController(coreDataStack: AppDelegate.coreDataStack)
//        let nvc = UINavigationController(rootViewController: breadListViewController)
        
        let foldersViewController = FoldersViewController()
        let nvc = UINavigationController(rootViewController: foldersViewController)
        
        nvc.navigationBar.prefersLargeTitles = true
        nvc.navigationBar.tintColor = .systemPink
        
        window?.rootViewController = nvc
        window?.makeKeyAndVisible()
    }
}

