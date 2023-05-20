//
//  ChatViewController.swift
//  ChatApp_Firebase
//
//  Created by Suraj on 20/05/23.
//

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore
import FirebaseAuth
import MessageKit
import SDWebImage

class ChatViewController: MessagesViewController , InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
        
    var currentUser: User?
    
    var user1UID: String = "cNFEAKkeMceQSzdW8xWJgYVmavo1"
    var user1Name: String = "Dev"
    
    var user2UID: String = "QRScZUNdA8OLAo9favNkzymm7dB2"
    var user2Name: String = "Admin"
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = user2Name ?? "Chat"
        
        navigationItem.largeTitleDisplayMode = .never
        maintainPositionOnKeyboardFrameChanged = true
        scrollsToLastItemOnKeyboardBeginsEditing = true
        
        messageInputBar.inputTextView.tintColor = .systemBlue
        messageInputBar.sendButton.setTitleColor(.systemTeal, for: .normal)
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        self.loginUsingEmailPassword()
        
    }
    
    func loginUsingEmailPassword(){
        
        Auth.auth().signIn(withEmail: "dev@gmail.com", password: "Dev123") { (user, error) in
            if error == nil{
                self.currentUser = user!.user
                self.sendMessage()
            }else{
                print("login error\(user)")
            }
            
        }
    }
    
    func sendMessage(){
        let db = Firestore.firestore().collection("Chats")
            .whereField("users", arrayContains: Auth.auth().currentUser?.uid ?? "Not Found User 1")
        
        db.getDocuments { (chatQuerySnap, error) in
            
            if let error = error {
                print("Error: \(error)")
                return
            } else {
                
                //Count the no. of documents returned
                guard let queryCount = chatQuerySnap?.documents.count else {
                    return
                }
                
                if queryCount == 0 {
                    //If documents count is zero that means there is no chat available and we need to create a new instance
                    self.createNewChat()
                }
                else if queryCount >= 1 {
                    //Chat(s) found for currentUser
                    for doc in chatQuerySnap!.documents {
                        
                        let chat = Chat(dictionary: doc.data())
                        //Get the chat which has user2 id
                        if (chat?.users.contains(self.user2UID))! {
                            self.docReference = doc.reference
                            //fetch it's thread collection
                            
                            doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                    if let error = error {
                                        print("Error: \(error)")
                                        return
                                    } else {
                                        self.messages.removeAll()
                                        for message in threadQuery!.documents {
                                            
                                            //let msg = Message(dictionary: message.data())
                                            let dict = message.data()
                                            let id = dict["id"] as! String
                                            let content = dict["content"] as! String
                                            let created = dict["created"] as! Timestamp
                                            let senderID = dict["senderID"] as! String
                                            let senderName = dict["senderName"] as! String
                                            
                                            
                                            let objMessage = Message(id: id, content: content, created: Date(), senderID: senderID, senderName: senderName)
                                            self.messages.append(objMessage)
                                            
                                        }
                                        self.messagesCollectionView.reloadData()
                                        self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                                    }
                                })
                        }
                        return
                    } //end of if
                } else {
                    print("Let's hope this error never prints!")
                }
            }
        }
    }
    
    // MARK: - Custom messages handlers
    
    func createNewChat() {
        var currentUser: User = Auth.auth().currentUser!
        let users = [currentUser.uid, self.user2UID]
        let data: [String: Any] = [
            "users":users
        ]
        
        let db = Firestore.firestore().collection("Chats")
        db.addDocument(data: data) { (error) in
            if let error = error {
                print("Unable to create chat! \(error)")
                return
            } else {
                self.sendMessage()
            }
        }
    }
    
    private func insertNewMessage(_ message: Message) {
        
        messages.append(message)
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        }
    }
    
    private func save(_ message: Message) {
        
        let data: [String: Any] = [
            "content": message.content,
            "created": message.created,
            "id": message.id,
            "senderID": message.senderID,
            "senderName": message.senderName
        ]
        
        docReference?.collection("thread").addDocument(data: data, completion: { (error) in
            
            if let error = error {
                print("Error Sending message: \(error)")
                return
            }
            
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
            
        })
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Date(), senderID: currentUser?.uid ?? "", senderName: currentUser?.displayName ?? "Admin")
        
        insertNewMessage(message)
        save(message)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    
    // MARK: - MessagesDataSource
    func currentSender() -> SenderType {
        
        return Sender(senderId: Auth.auth().currentUser!.uid, displayName: "Admin")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
        
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        
        if messages.count == 0 {
            print("No messages to display")
            return 0
        } else {
            return messages.count
        }
    }
    
    
    // MARK: - MessagesLayoutDelegate
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    // MARK: - MessagesDisplayDelegate
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .blue: .lightGray
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        var currentUser: User = Auth.auth().currentUser!
        
        if message.sender.senderId == currentUser.uid {
            SDWebImageManager.shared.loadImage(with: currentUser.photoURL, options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
                avatarView.image = image
            }
        } else {
            SDWebImageManager.shared.loadImage(with: URL(string: ""), options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
                avatarView.image = image
            }
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
        
    }
}
