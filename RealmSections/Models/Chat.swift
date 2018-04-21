//
//  Chat.swift
//  TestProject
//
//  Created by Vladislav Sedinkin on 18.04.18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import UIKit
import RealmSwift

class Chat: Object {

    @objc dynamic var id: String = ""
    let messages = List<Message>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

class Message: Object {
    
    @objc dynamic var id: String = ""
    @objc dynamic var chatId: String = ""
    @objc dynamic var textContent: TextContent?
    @objc dynamic var sortValue: Int = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}

class TextContent: Object {
    
    @objc dynamic var id: String = ""
    @objc dynamic var ownerId: String = ""

    let owners = LinkingObjects(fromType: Message.self, property: "textContent")
    var owner: Message? {
        return owners.first
    }
//    var owner: Message? {
//        let realm = try! Realm()
//        return realm.object(ofType: Message.self, forPrimaryKey: ownerId)
//    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
}
