//
//  GoogleHelper.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/01.
//

import Foundation
import GoogleSignIn

final class GoogleHelper {
    static let sharedInstance = GoogleHelper()
    
    func signIn(presenting viewController: UIViewController) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() == false {
            let signInConfig = GIDConfiguration(clientID: APIKeys.googleDriveClientID)
            GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: viewController) { user, error in
                guard error == nil else {
                    print("에러 발생")
                    return
                }
                
                guard user != nil else {
                    print("로그인실패!")
                    return
                }
                
                self.addDriveReadOnlyScope(presenting: viewController)
            }
        } else {
            addDriveReadOnlyScope(presenting: viewController)
        }
    }
    
    func addDriveReadOnlyScope(presenting viewController: UIViewController) {
        if GIDSignIn.sharedInstance.currentUser?.grantedScopes?.firstIndex(of: kGTLRAuthScopeDriveReadonly) == nil {
            GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDriveReadonly], presenting: viewController){ user, error in
                guard let user = user, error == nil else {
                    print("로그인실패!")
                    return
                }
                
                print("성공!")
            }
        }
    }
}

final class GoogleDriveService {
    static let sharedInstance = GoogleDriveService()

    let service = GTLRDriveService()
    
    func listsFolders(onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.spaces = "drive"
        query.corpora = "user"
        
        query.pageSize = 100
        query.q = "mimeType = 'application/vnd.google-apps.folder'"
        
        self.service.executeQuery(query) { (ticket, result, error) in
            print("ticket=\(ticket)")
            print("결과=\(result ?? "결과없음")")
            print("error=\(error)")
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
}
