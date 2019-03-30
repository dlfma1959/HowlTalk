//
//  ChatRoomsViewController.swift
//  HowlTalk
//
//  Created by Jeong HyunJi on 30/01/2019.
//  Copyright © 2019 Jeong HyunJi. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableview: UITableView!
    
    var uid : String!
    var chatrooms : [ChatModel]! = []
    var keys : [String] = []
    var destinationUsers : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.uid = Auth.auth().currentUser?.uid
        self.getChatroomsList()

        // Do any additional setup after loading the view.
    }
    
    func getChatroomsList(){
        
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            
            self.chatrooms.removeAll()
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                
                
                if let chatroomdic = item.value as? [String:AnyObject]{
                    let chatModel = ChatModel(JSON: chatroomdic)
                    chatModel?.uesrcnt = chatModel!.users.count
                    chatModel?.chatkey = item.key
                    self.keys.append(item.key)
                    self.chatrooms.append(chatModel!)
                }
            }
            
            self.tableview.reloadData()
            
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        var destinationUid :String?
        
        for item in self.chatrooms[indexPath.row].users{
            
            if(item.key != self.uid){
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
            }
        }
        
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
            
            if(self.chatrooms[indexPath.row].uesrcnt > 2){
                cell.label_usercnt.text = String(self.chatrooms[indexPath.row].uesrcnt)
                var label_title_userName :String = ""
                
                for iusersKey in self.chatrooms[indexPath.row].users{
                    
                    if(iusersKey.key != self.uid){
                    
                        Database.database().reference().child("users").child(iusersKey.key).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
                            
                            let userModel = UserModel()
                            
                            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
                            
                            if(label_title_userName != ""){
                                
                                label_title_userName = label_title_userName + ", "
                            }
                            label_title_userName = label_title_userName + userModel.userName!
                            
                            cell.label_title.text = label_title_userName
                            
                        })
                    }
                }
                
            }else{
                cell.label_usercnt.text = ""
                cell.label_title.text = userModel.userName
            }
            
            let url = URL(string:userModel.profileImageUrl!)
            //대화방 리스트에서 이미지 동그랗게 출력
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            if(self.chatrooms[indexPath.row].comments.keys.count == 0){
                //채팅방을 처음만들어서 대화가없을 경우 코드 중지해서 에러 방지
                return
            }
            
            let lastMessagekey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.label_lastmessage.text = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.message
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.timestamp
            cell.label_timestamp.text = unixTime?.toDayTime
        })
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //리스트 클릭할때 발생하는 이벤트
//
//        print(self.destinationUsers[indexPath.row], 111111, separator: " : ")
//     //   print(indexPath, 22222222, separator: " : ")
//        print(self.chatrooms[indexPath.row].users, 33333, separator: " : ")
//        print(self.chatrooms[indexPath.row].users.keys.first, 4444, separator: " : ")
//
        tableView.deselectRow(at: indexPath, animated: true)
        
        if(self.chatrooms[indexPath.row].uesrcnt > 2){
            
            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
            view.destinationRoom = self.chatrooms[indexPath.row].chatkey
            self.navigationController?.pushViewController(view, animated: true)
            
        }else{
            
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            view.destinationUid = self.chatrooms[indexPath.row].users.keys.first
            self.navigationController?.pushViewController(view, animated: true)
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
         viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*.
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}

class CustomCell: UITableViewCell{
    @IBOutlet weak var label_timestamp: UILabel!
    @IBOutlet weak var label_lastmessage: UILabel!
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label_usercnt: UILabel!
    
}
