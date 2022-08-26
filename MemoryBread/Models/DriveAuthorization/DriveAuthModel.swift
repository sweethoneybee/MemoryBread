//
//  DriveAuthModel.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/16.
//

import Foundation
import GoogleSignIn
import Combine

final class DriveAuthModel {
    
    private var authInfos: [DriveAuthInfo] = {
        let storage = DriveAuthStorage.shared

        // append DriveAuthInfo manually in code to connect new drive service.
        var arr: [DriveAuthInfo] = []
        arr.append(
            DriveAuthInfo(
                domain: .googleDrive,
                isSignIn: (storage.googleDrive.value != nil) ? true : false,
                userEmail: storage.googleDrive.value?.userEmail ?? nil
            )
        )
        
        return arr
    }() {
        didSet {
            DispatchQueue.main.async {
                self.driveAuthStorageHasChanged?()
            }
        }
    }
    
    var driveAuthStorageHasChanged: (() -> ())?
    var observers: [NSKeyValueObservation] = []
    var cancellabes: Set<AnyCancellable> = []
    init() {
        DriveAuthStorage.shared.googleDrive.sink { [weak self] authorization in
            let index = DriveDomain.googleDrive.rawValue
            
            guard let authorization = authorization else {
                self?.authInfos[index] = DriveAuthInfo(
                    domain: .googleDrive,
                    isSignIn: false,
                    userEmail: nil
                )
                return
            }
            
            self?.authInfos[index] = DriveAuthInfo(
                domain: .googleDrive,
                isSignIn: true,
                userEmail: authorization.userEmail
            )
        }.store(in: &cancellabes)
    }
}

extension DriveAuthModel {
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
                    completionHandler(error)
                    return
                }
                DriveAuthStorage.shared.googleDrive.value = user?.authentication.fetcherAuthorizer()
                completionHandler(nil)
            }
        }
    }
    
    func signOut(at index: Int) {
        let domain = authInfos[index].domain
        switch domain {
        case .googleDrive:
            GIDSignIn.sharedInstance.signOut()
            DriveAuthStorage.shared.googleDrive.value = nil
        }
    }
    
    func drive(at index: Int) -> DriveDomain {
        return authInfos[index].domain
    }
}
