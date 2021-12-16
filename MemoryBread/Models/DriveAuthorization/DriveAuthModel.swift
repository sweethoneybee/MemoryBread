//
//  DriveAuthModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/16.
//

import Foundation
import GoogleSignIn

final class DriveAuthModel {
    enum SignError: Error {
        case userCancel
        case thirdPartyError
    }
    
    private var authInfos: [DriveAuthInfo] = {
        let storage = DriveAuthStorage.shared

        var arr: [DriveAuthInfo] = []
        arr.append(
            DriveAuthInfo(
                domain: .googleDrive,
                isSignIn: (storage.googleDrive != nil) ? true : false,
                userEmail: storage.googleDrive?.userEmail ?? nil
            )
        )
        
        return arr
    }() {
        didSet {
            DispatchQueue.main.async {
                self.changedDatasource?()
            }
        }
    }
    
    var changedDatasource: (() -> ())?
    var observers: [NSKeyValueObservation] = []
    
    init() {
        observers.append(DriveAuthStorage.shared.observe(\.googleDrive, options: [.new]) { _, change in
            let index = DriveAuthInfo.Domain.googleDrive.rawValue
            if let newValue = change.newValue,
               let auth = newValue {
                self.authInfos[index] = DriveAuthInfo(domain: .googleDrive, isSignIn: true, userEmail: auth.userEmail)
                return
            }
            self.authInfos[index] = DriveAuthInfo(domain: .googleDrive, isSignIn: false, userEmail: nil)
        })
    }
    
    func authInfo(at index: Int) -> DriveAuthInfo {
        return authInfos[index]
    }
    
    func isSignIn(at index: Int) -> Bool {
        return authInfos[index].isSignIn
    }
    
    func signIn(at index: Int, modalView: UIViewController, completionHandler: @escaping (Error?) -> ()) {
        let domain = authInfos[index].domain
        switch domain {
        case .googleDrive:
            let configure = GIDConfiguration(clientID: APIKeys.googleDriveClientID)
            GIDSignIn.sharedInstance.signIn(with: configure, additionalScopes: [kGTLRAuthScopeDriveReadonly], presenting: modalView) { user, error in
                if error != nil {
                    completionHandler(SignError.userCancel)
                    return
                }
                DriveAuthStorage.shared.googleDrive = user?.authentication.fetcherAuthorizer()
                completionHandler(nil)
            }
        }
    }
    
    func signOut(at index: Int) {
        let domain = authInfos[index].domain
        switch domain {
        case .googleDrive:
            GIDSignIn.sharedInstance.signOut()
            DriveAuthStorage.shared.googleDrive = nil
        }
    }
}
