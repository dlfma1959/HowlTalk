//
//  LoginViewController.swift
//  HowlTalk
//
//  Created by Jeong HyunJi on 22/01/2019.
//  Copyright © 2019 Jeong HyunJi. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signup: UIButton!
    
    let remoteconfig = RemoteConfig.remoteConfig()
    var color : String! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //파이어베이스 개발중에 로그인 되있는 상태로 개발중이라 임의로 로그아웃 상태만들어줌
        try! Auth.auth().signOut()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints{ (m) in
            m.right.top.left.equalTo(self.view)
            //아이폰X 배경 윗 배경 채우기
            if(UIScreen.main.nativeBounds.height == 2436){
                m.height.equalTo(40)
            }else{
                m.height.equalTo(20)
            }
        }
        
        color = remoteconfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        signup.backgroundColor = UIColor(hex: color)
        
        loginButton.addTarget(self, action: #selector(loginEvent), for: .touchUpInside)
        signup.addTarget(self, action: #selector(presentSigup), for: .touchUpInside)
        
        Auth.auth().addStateDidChangeListener{ (auth, user) in
            if(user != nil){
                
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as! UITabBarController
                self.present(view, animated: true, completion: nil)
                
            }
        }

        // Do any additional setup after loading the view.
    }
    
    @objc func loginEvent(){
    
        Auth.auth().signIn(withEmail: email.text!, password: password.text!){ (user, err) in
            
            if(err != nil){
                
                let alert = UIAlertController(title: "에러", message: err.debugDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    }
    
    @objc func presentSigup(){
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        self.present(view, animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
