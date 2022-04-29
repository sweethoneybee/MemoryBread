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
        
        let foldersViewController = FoldersViewController(coreDataStack: AppDelegate.coreDataStack)
        let nvc = UINavigationController(rootViewController: foldersViewController)
        
        nvc.navigationBar.prefersLargeTitles = true
        nvc.navigationBar.tintColor = .systemPink
        
        window?.rootViewController = nvc
        window?.makeKeyAndVisible()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        let context = AppDelegate.coreDataStack.writeContext
        context.perform {
            do {
                try context.save()
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

