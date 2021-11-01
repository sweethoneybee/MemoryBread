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
        
//        for _ in 0..<20 {
//            let bread = Bread(touch: Date.now,
//                              directoryName: "임시 폴더",
//                              title: "임시 타이틀",
//                              content: Page.sampleContent,
//                              separatedContent: Page.sampleSeparatedContent,
//                              filterIndexes: Array(repeating: [], count: FilterColor.count))
//            BreadDAO().save()
//        }
//        BreadDAO().deleteAll()
        let breadListViewController = BreadListViewController()
        let nvc = UINavigationController(rootViewController: breadListViewController)
        nvc.navigationBar.prefersLargeTitles = true
        window?.rootViewController = nvc
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

