//
//  GoogleLoginTestViewController.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/12/01.
//

import UIKit
import SnapKit
import GoogleSignIn

class GoogleLoginTestViewController: UIViewController {
    let button = UIButton(type: .system).then {
        $0.setTitle("드라이브 로그인", for: .normal)
    }
    
    let folderButton = UIButton(type: .system).then {
        $0.setTitle("폴더목록", for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(200)
            make.center.equalToSuperview()
        }
        button.addTarget(self, action: #selector(signInGoogleDrive), for: .touchUpInside)
        
    
        view.addSubview(folderButton)
        folderButton.snp.makeConstraints { make in
            make.width.height.equalTo(200)
            make.centerX.equalToSuperview()
            make.top.equalTo(button.snp.bottom)
        }
        folderButton.addTarget(self, action: #selector(listsFolders), for: .touchUpInside)
        
    }
    
    @objc
    func signInGoogleDrive() {
        GoogleHelper.sharedInstance.signIn(presenting: self)
    }
    
    @objc
    func listsFolders() {
        GoogleDriveService.sharedInstance.listsFolders { fileList, error in
            guard error != nil else {
                print("파일 가져오기 에러")
                return
            }
            guard let fileList = fileList else {
                print("파일 가져오기 실패")
                return
            }

            print("파일들=\(fileList.files)")
            print("json=\(fileList.jsonString())")
        }
    }
}

