//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by Jeong HyunJi on 31/01/2019.
//  Copyright © 2019 Jeong HyunJi. All rights reserved.
//

import UIKit
import Firebase

class GroupChatRoomViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var bottomContraint: NSLayoutConstraint!
    @IBOutlet weak var textfiled_message: UITextField!
    @IBOutlet weak var button_send: UIButton!
    @IBOutlet weak var tableview: UITableView!
    var destinationRoom : String?
    var uid : String?
    var databaseRef : DatabaseReference?
    var observe : UInt?
    var comments : [ChatModel.Comment] = []
    var users : [String:AnyObject]?
    var peopleCount : Int?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            self.users = datasnapshot.value as! [String:AnyObject]
        })
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        // Do any additional setup after loading the view.
        getMessageList()
    }
    
    //시작
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    //종료
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
        databaseRef?.removeObserver(withHandle: observe!)
    }
    
    @objc func keyboardWillShow(notification : Notification){
        
        if let keyboardSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue{
            
            self.bottomContraint.constant = keyboardSize.height + 20
        }
        
        UIView.animate(withDuration: 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: {
            (complete) in
            
            //문자 전송시 스크롤 제일 아래로
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
        })
    }
    
    @objc func keyboardWillHide(notification:Notification){
        
        self.bottomContraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    
    @objc func sendMessage(){
        
        let value : Dictionary<String,Any> = [
            "uid" : uid!,
            "message" : textfiled_message.text!,
            "timestamp" : ServerValue.timestamp()
        ]
        
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value){ (err, ref) in
            self.textfiled_message.text = ""
            
            Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
                let dic = datasnapshot.value as! [String:Any]
            })
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        if(self.comments[indexPath.row].uid == uid){
            // 내가 쓴 대화
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            return view
        }else{
            // 타인이 한 대화
            let destinationUsesr = users![self.comments[indexPath.row].uid!]
            let view = tableView.dequeueReusableCell( withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUsesr!["userName"] as! String
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0;
            let imageUrl = destinationUsesr!["profileImageUrl"] as! String
            let url = URL(string: (imageUrl))
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            view.imageview_profile.kf.setImage(with: url)
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            return view
        }
        
        return UITableViewCell()
        
    }
    
    func setReadCount(label:UILabel?, position: Int?){
        //채팅방에 읽은 수 카운트 가져오기
        let readCount = self.comments[position!].readUsers.count
        if(peopleCount == nil){
            
            Database.database().reference().child("chatrooms").child(destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value) { (datasnapshot) in
                
                let dic = datasnapshot.value as! [String:Any]
                self.peopleCount = dic.count
                let noReadCount = self.peopleCount! - readCount
                if(noReadCount > 0){
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                }else{
                    label?.isHidden = true
                }
            }
        }else{
            let noReadCount = peopleCount! - readCount
            if(noReadCount > 0){
                label?.isHidden = false
                label?.text = String(noReadCount)
            }else{
                label?.isHidden = true
            }
        }
    }
    
    
    func getMessageList(){
        
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
        observe = databaseRef?.observe(DataEventType.value, with: { (datasnapshot) in
            
            // 데이터 누적 방지
            self.comments.removeAll()
            var readUserDic : Dictionary<String,AnyObject> = [:]
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                let comment_motify = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                comment_motify?.readUsers[self.uid!] = true
                readUserDic[key] = comment_motify?.toJSON() as! NSDictionary
                self.comments.append(comment!)
            }
            
            let nsDic = readUserDic as NSDictionary
            
            if(self.comments.last?.readUsers.keys == nil){
                //채팅방을 처음만들어서 대화가없을 경우 코드 중지해서 에러 방지
                return
            }
            
            if(!(self.comments.last?.readUsers.keys.contains(self.uid!))!){
                
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                    self.tableview.reloadData()
                    //문자 전송시 스크롤 제일 아래로
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
                    }
                })
            }else{
                
                self.tableview.reloadData()

                //문자 전송시 스크롤 제일 아래로
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
                }

                    
            }
            
        })
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
