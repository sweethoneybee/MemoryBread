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
    lazy var coreDataStack: CoreDataStack = {
        return CoreDataStack(modelName: "MemoryBread")
    }()
    static var coreDataStack: CoreDataStack {
        return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    }
    
    // MARK: - application methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if UserManager.firstLaunch {
            createInitialObjects()
            UserManager.firstLaunch = false
        }
        
        if !UserManager.didNewLineMigration {
            migrateForNewLine()
            UserManager.didNewLineMigration = true
        }
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error == nil && user != nil {
                DriveAuthStorage.shared.googleDrive.value = user?.authentication.fetcherAuthorizer()
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
    
    func applicationSignificantTimeChange(_ application: UIApplication) {
        NotificationCenter.default.post(Notification(name: .updateViewsForTimeChange))
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
        let context = coreDataStack.viewContext
        
        let _ = Folder(
            context: context,
            id: UUID(),
            isSystemFolder: true,
            pinnedAtTop: true,
            pinnedAtBottom: false,
            name: LocalizingHelper.allMemoryBreads,
            index: 0,
            breads: nil
        )
        
        
        let defaultFolder = Folder(
            context: context,
            id: UUID(),
            isSystemFolder: false,
            pinnedAtTop: true,
            pinnedAtBottom: false,
            name: LocalizingHelper.defaultFolder,
            index: 1,
            breads: nil
        )
        UserManager.defaultFolderID = defaultFolder.id.uuidString
        
        let trash = Folder(
            context: context,
            id: UUID(),
            isSystemFolder: true,
            pinnedAtTop: false,
            pinnedAtBottom: true,
            name: LocalizingHelper.trash,
            index: 2,
            breads: nil
        )
        UserManager.trashFolderID = trash.id.uuidString
        
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
        context.saveIfNeeded()
    }
}

// MARK: - Migration
enum MigrationError: Error {
    case fetchingFail
    case saveFail
    
    var localizedDescription: String {
        var sentence = "migration_fail".localized
        switch self {
        case .fetchingFail: sentence += "(" + "fetching_memory_bread_error".localized + ")"
        case .saveFail: sentence += "(" + "saving_miagrion_result_error".localized + ")"
        }
        
        sentence += ". " + "contact_developer".localized
        return sentence
    }
}

var migrationError: MigrationError? = nil

extension AppDelegate {
    private func migrateForNewLine() {
        func splitWithChar(_ arr: inout [String], for str: String, using char: Character) {
            guard !str.isEmpty else { return }
            var firstIndex = str.firstIndex(of: char) ?? str.endIndex
            
            if firstIndex != str.startIndex {
                arr.append(String(str[..<firstIndex]))
                splitWithChar(&arr, for: String(str[firstIndex...]), using: char)
                return
            }
            
            arr.append(String(str[firstIndex]))
            firstIndex = str.index(after: firstIndex)
            splitWithChar(&arr, for: String(str[firstIndex...]), using: char)
        }
        
        func countNewLine(of splittedContentWithNewLine: [String], atLength length: Int) -> [Int] {
            var newLineCounter = Array(repeating: 0, count: length)
            var count = 0
            var index = 0
            splittedContentWithNewLine.forEach {
                if $0 == "\n" {
                    count += 1
                    return
                }
                newLineCounter[index] = count
                index += 1
            }
            
            return newLineCounter
        }
        
        let fc = Bread.fetchRequest()
        let context = coreDataStack.viewContext
        
        let breads: [Bread]
        do {
            breads = try context.fetch(fc)
        } catch {
            UserManager.didNewLineMigration = false
            migrationError = .fetchingFail
            return
        }
        
        for bread in breads {
            var countEmptyString = 0
            let numberOfEmptyString: [Int] = bread.separatedContent.map {
                if $0 == "" {
                    countEmptyString += 1
                }
                return countEmptyString
            }
            
            // 기존 filterIndexes가 ""를 포함한 separatedContent로부터
            // index값을 저장하고 있었기 때문에, ""를 제거한 index 값으로 업데이트
            var newFilterIndexes = bread.filterIndexes.map { row in
                row.map { index in
                    return index - numberOfEmptyString[index]
                }
            }
            
            var tempSeparatedContent = bread.content.components(separatedBy: [" ", "\t"])
            tempSeparatedContent.removeAll { $0 == "" }
            
            var newSeparatedContent: [String] = []
            tempSeparatedContent.forEach {
                splitWithChar(&newSeparatedContent, for: $0, using: "\n")
            }
            
            // 위의 filterIndexes가 ""를 제거한 상태의 index로 업데이트 되었기에
            // 기존 separatedContent도 ""를 제거하여 사용
            var oldSeparatedContent = bread.separatedContent
            oldSeparatedContent.removeAll { $0 == "" }
            
            let numberOfNewLines = countNewLine(
                of: newSeparatedContent,
                atLength: oldSeparatedContent.count
            )
            
            // filterIndexes를 중간중간 추가된 \n 개수에 맞게
            // index를 업데이트
            newFilterIndexes = newFilterIndexes.map { row in
                row.map { index in
                    return index + numberOfNewLines[index]
                }
            }
            bread.separatedContent = newSeparatedContent
            bread.filterIndexes = newFilterIndexes
        }
        
        do {
            try context.save()
            UserManager.didNewLineMigration = true
        } catch {
            UserManager.didNewLineMigration = false
            migrationError = .saveFail
            return
        }
    }
}

