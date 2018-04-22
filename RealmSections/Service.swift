//
//  Service.swift
//  TestProject
//
//  Created by Vladislav Sedinkin on 18.04.18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import UIKit
import RealmSwift

extension Realm {
    
    func safeWrite(_ block: () throws -> Void) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
    
}

class Service {

    func addInitValues() {
        let realm = try! Realm()
        guard realm.objects(Chat.self).isEmpty else {
            return
        }
        
        var indexes: [Int] = []
        for index in 0..<15 {
            indexes.append(index)
        }
        
        var messages: [Message] = []
        indexes.forEach {
            let message = Message(value: ["id": "\($0)", "chatId": "0", "sortValue": $0 + Int(arc4random_uniform(21) + 10)])
            messages.append(message)
        }
        
        let firstChat = Chat(value: ["id": "0", "messages": messages])
        
        try! realm.safeWrite {
            realm.add(firstChat, update: true)
        }
        
    }
    
    func appendNew() {
        let realm = try! Realm()
        
        var indexes: [Int] = []
        for index in 2100..<2200 {
            indexes.append(index)
        }
        
        var messages: [Message] = []
        indexes.forEach {
            let message = Message(value: ["chatId": "0", "id": "\($0)", "sortValue": $0 + Int(arc4random_uniform(21) + 10)])
            messages.append(message)
        }
        
        let firstChat = Chat(value: ["id": "0", "messages": messages])

        
        try! realm.safeWrite {
            realm.add(firstChat, update: true)
        }
        
    }
    
    func addSecondChat() {
        let realm = try! Realm()
        guard realm.objects(Chat.self).count == 1 else {
            return
        }
        var indexes: [Int] = []
        for index in 800..<900 {
            indexes.append(index)
        }
        var messages: [Message] = []
        indexes.forEach {
            let message = Message()
            message.id = "\($0)"
            message.sortValue = $0 + Int(arc4random_uniform(21) + 10)
            
            messages.append(message)
        }
        
        let secondChat = Chat(value: ["id": "1", "messages": messages])
        try! realm.safeWrite {
            realm.add(secondChat, update: true)
        }
    }
    
    func addRandomMessage() {
        let realm = try! Realm()
        let chat = realm.objects(Chat.self).first!
        let message1 = Message(value: ["id": "\(UUID().uuidString)", "sortValue": 2, "chatId": "0"])
        let message2 = Message(value: ["id": "\(UUID().uuidString)", "sortValue": 5, "chatId": "0"])
        let message3 = Message(value: ["id": "\(UUID().uuidString)", "sortValue": 12, "chatId": "0"])
        let message4 = Message(value: ["id": "\(UUID().uuidString)", "sortValue": 16, "chatId": "0"])
        try! realm.safeWrite {
            realm.add([message1, message2, message3, message4], update: true)
//            chat.messages.append(message)
        }
    }
    
    func removeLastMessage() {
        let realm = try! Realm()
        let chat = realm.objects(Chat.self).first!
        try! realm.safeWrite {
            realm.delete(chat.messages.first!)
        }
    }
    
    func removeAll() {
        let realm = try! Realm()
        let chat = realm.objects(Chat.self).first!
        try! realm.safeWrite {
            printTimeElapsedWhenRunningCode(title: "Remove all", operation: {
                appendNew()
//                chat.messages.removeAll()
//                chat.messages.append(objectsIn: realm.objects(Message.self).filter("chatId == %@", "0").sorted(byKeyPath: "sortValue", ascending: true))
            })
        }
    }
    
    func addDuplicateArary() {
        let realm = try! Realm()
        let chat = realm.objects(Chat.self).first!
        let messages = realm.objects(Message.self).filter("chatId == %@", "\(0)")
        
        try! realm.safeWrite {
            chat.messages.append(objectsIn: messages)
        }
    }
    
    func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed for \(title): \(timeElapsed) s.")
    }
    
}
