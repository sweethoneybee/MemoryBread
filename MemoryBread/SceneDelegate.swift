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

        if UserManager.firstLaunch {
            Tutorial().infos.forEach {
                let tutorialBread = BreadDAO.default.create()
                tutorialBread.title = $0.title
                tutorialBread.updateContent($0.content)
                tutorialBread.updateFilterIndexes(usingIndexes: $0.filterIndexes)
            }
            BreadDAO.default.save()
            UserManager.firstLaunch = false
        }
        
        let breadListViewController = BreadListViewController()
        let nvc = UINavigationController(rootViewController: breadListViewController)
        nvc.navigationBar.prefersLargeTitles = true
        nvc.navigationBar.tintColor = .systemPink
        
        window?.rootViewController = nvc
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

