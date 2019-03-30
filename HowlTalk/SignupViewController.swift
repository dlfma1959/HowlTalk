//
//  SignupViewController.swift
//  HowlTalk
//
//  Created by Jeong HyunJi on 22/01/2019.
//  Copyright © 2019 Jeong HyunJi. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signup: UIButton!
    @IBOutlet weak var cancel: UIButton!
    
    let remoteconfig = RemoteConfig.remoteConfig()
    var color : String! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints{ (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(20)
        }
        color = remoteconfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signup.backgroundColor = UIColor(hex: color)
        cancel.backgroundColor = UIColor(hex: color)
        
        signup.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc func imagePicker(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(imagePicker, animated:  true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imageView.image = (info[UIImagePickerController.InfoKey.originalImage] as! UIImage)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func signupEvent(){
        Auth.auth().createUser(withEmail: email.text!, password: password.text!){ (user, error) in
            
            let uid = user?.user.uid
            let image = self.imageView.image?.jpegData(compressionQuality: 0.1)
            
            Storage.storage().reference().child("userImages").child(uid!).putData(image!, metadata: nil, completion: {(StorageMetadata, Error) in
                
                Storage.storage().reference().child("userImages").child(uid!).downloadURL(completion: { (url, err) in
                    
                    let values = ["userName" : self.name.text, "profileImageUrl" : url?.absoluteString, "uid" : Auth.auth().currentUser?.uid]
                    
                    Database.database().reference().child("users").child(uid!).setValue(values, withCompletionBlock: { (err, ref) in
                        if(err==nil){
                            self.cancelEvent()
                        }
                    })
                })
            })
            
        }
    }
    
    @objc func cancelEvent(){
        self.dismiss(animated: true, completion: nil)
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
