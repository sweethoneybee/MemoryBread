//
//  AppDelegate.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/10/24.
//

import UIKit
import CoreData
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Core Data stack
    lazy var coreDataStack = CoreDataStack(modelName: "MemoryBread")
    static var coreDataStack: CoreDataStack {
        return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    }
    
    // MARK: - application methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if UserManager.firstLaunch {
            createInitialObjects()
            UserManager.firstLaunch = false
        }
        
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error == nil && user != nil {
                DriveAuthStorage.shared.googleDrive = user?.authentication.fetcherAuthorizer()
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - OepnURL
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        
        return false
    }
}

extension AppDelegate {
    private func createInitialObjects() {
        let context = coreDataStack.writeContext
        
        let allMemoryBreadFolder = Folder(context: context)
        allMemoryBreadFolder.id = UUID()
        allMemoryBreadFolder.name = LocalizingHelper.allMemoryBreads
        allMemoryBreadFolder.index = 0
        allMemoryBreadFolder.pinnedAtTop = true
        allMemoryBreadFolder.isSystemFolder = true
        
        let defaultFolder = Folder(context: context)
        defaultFolder.id = UUID(uuidString: UserManager.defaultFolderID)
        defaultFolder.name = LocalizingHelper.appTitle
        defaultFolder.index = 1
        defaultFolder.pinnedAtTop = true
        
        let trash = Folder(context: context)
        trash.id = UUID(uuidString: UserManager.trashFolderID)
        trash.name = LocalizingHelper.trash
        trash.index = 2
        trash.pinnedAtBottom = true
        trash.isSystemFolder = true
        
        Tutorial().infos.forEach {
            let tutorialBread = Bread(
                context: context,
                title: $0.title,
                content: $0.content,
                selectedFilters: [],
                folder: defaultFolder
            )
            tutorialBread.updateFilterIndexes(usingIndexes: $0.filterIndexes)
        }
        context.saveContextAndParentIfNeeded()
    }
}

