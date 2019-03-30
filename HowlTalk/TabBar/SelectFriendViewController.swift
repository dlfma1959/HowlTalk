//
//  SelectFriendViewController.swift
//  HowlTalk
//
//  Created by Jeong HyunJi on 31/01/2019.
//  Copyright © 2019 Jeong HyunJi. All rights reserved.
//

import UIKit
import Firebase
import BEMCheckBox

class SelectFriendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BEMCheckBoxDelegate {
    var users = Dictionary<String,Bool>()
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tableview: UITableView!
    var array : [UserModel] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        
        view.labelName.text = array[indexPath.row].userName
        view.imageviewProfile.kf.setImage(with: URL(string: array[indexPath.row].profileImageUrl!))
        view.checkbox.delegate = self
        view.checkbox.tag = indexPath.row
        
        return view
    }
    
    func didTap(_ checkBox: BEMCheckBox) {
        if(checkBox.on){
            //체크박스가 체크시 때 발생 이벤트
            users[self.array[checkBox.tag].uid!] = true
            
        }else{
            //체크박스가 해제시 때 발생 이벤트
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
            
        }
    }
    
    @objc func createRoom(){
        let myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        let nsDic = users as NSDictionary
        
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+myUid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            
          //  print(datasnapshot, nsDic, 4444, separator: " : ")
            
            var chatRoomUserArr : [String:Bool] = [:]
            var chkBoolChatRoom : Bool = false;
            let datasnapshot = datasnapshot.children.allObjects as! [DataSnapshot]
            var chkBool = false;
            var goChatroomKey : String = ""
            
            if(datasnapshot.count > 0){
                
                //사용자가 참여한 모든 채팅방 가져오기
                for item in datasnapshot{
                    if let chatRoomdic = item.value as? [String:AnyObject]{
                        let chatModel = ChatModel(JSON: chatRoomdic)
                        chatRoomUserArr = (chatModel?.users)!
                        
                        //참여자수 같은 방이 있는지 체크
                        if(chatRoomUserArr.count == nsDic.count){
                            
                            //해당방에서 참여한 유저리스트 가져와 ichatRoomUserArr 저장해서 반복문 돌리기
                            for ichatRoomUserArr in chatRoomUserArr {
                                
                                //각 참여 유저와 지금 대화방 만들 유저 리스트 비교하는 반복문
                                for insDic in nsDic{
                                    let insDicKey =  insDic.key as? String ?? ""
                                    if ichatRoomUserArr.key == insDicKey{
                                        //채팅방에 해당유저가 있을 경우 해당 유저 목록 삭제
                                        chatRoomUserArr.removeValue(forKey: insDicKey)
                                        break;
                                    }
                                }
                            }
                            
                            if(chatRoomUserArr.count == 0){
                                chkBoolChatRoom = true;
                                goChatroomKey = item.key;
                                break;
                            }
                        }
                        
                    }
                }
                
                if(chkBoolChatRoom == true){
     //               print(chkBoolChatRoom, chkBool, goChatroomKey, separator: " : ")
                    //이미 개설된 방이 있는 경우 방 키를 넣어 그룹채팅 방으로 가기
                    
                    let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
                    view.destinationRoom = goChatroomKey
                    self.navigationController?.pushViewController(view, animated: true)
                    
                }else{
                    
                    //이미 개설된 방이 없는 경우 그룹채팅방 만들고 그룹채팅방으로 이동
                    Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic, withCompletionBlock: { (err, ref) in
                        
                        let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
                        view.destinationRoom = ref.key
                        self.navigationController?.pushViewController(view, animated: true)
                    })
                }
            }else{
            
                //이미 개설된 방이 없는 경우 그룹채팅방 만들고 그룹채팅방으로 이동 
                Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic, withCompletionBlock: { (err, ref) in
                    
                    let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
                    view.destinationRoom = ref.key
                    self.navigationController?.pushViewController(view, animated: true)
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Database.database().reference().child("users").observe(DataEventType.value, with: { (snapshot) in
            
            self.array.removeAll()
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children{
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                userModel.setValuesForKeys(fchild.value as! [String : Any])
                
                if(userModel.uid == myUid){
                    continue
                }
                self.array.append(userModel)
            }
            DispatchQueue.main.async {
                self.tableview.reloadData();
            }
        })
        button.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

class SelectFriendCell : UITableViewCell {
    
    @IBOutlet weak var checkbox: BEMCheckBox!
    @IBOutlet weak var imageviewProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
}
