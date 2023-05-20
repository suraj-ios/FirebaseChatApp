//
//  Message.swift
//  ChatApp_Firebase
//
//  Created by Suraj on 20/05/23.
//

import Foundation
import UIKit
import Firebase
import MessageKit

struct Message {
    var id: String
    var content: String
    var created: Date
    var senderID: String
    var senderName: String
    var dictionary: [String: Any] {
        return [
            "id": id,
            "content": content,
            "created": created,
            "senderID": senderID,
            "senderName":senderName]
    }
}
extension Message {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let content = dictionary["content"] as? String,
              let created = dictionary["created"] as? Date,
              let senderID = dictionary["senderID"] as? String,
              let senderName = dictionary["senderName"] as? String
        else {return nil}
        self.init(id: id, content: content, created: created, senderID: senderID, senderName:senderName)
    }
}

extension Message: MessageType {
    var sender: SenderType {
        return ChatUser(senderId: senderID, displayName: senderName)
    }
    var messageId: String {
        return id
    }
    var sentDate: Date {
        return Date()
    }
    var kind: MessageKind {
        return .text(content)
    }
}
