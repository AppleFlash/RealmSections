//
//  ViewController.swift
//  TestProject
//
//  Created by Vladislav Sedinkin on 13.03.18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    private let service = Service()
    @IBOutlet weak var tableView: UITableView!
    
    var notification: NotificationToken?
    var messages: Results<Message>!
    lazy var chat: Chat = {
        let realm = try! Realm()
        return realm.objects(Chat.self).first!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        messages = try! Realm().objects(Message.self).filter("chatId == %@", "0").sorted(byKeyPath: "sortValue", ascending: true)
        notification = messages.observe({ (changes) in
            switch changes {
            case .initial(_):
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                self.messageStorage.expectedCount = deletions.count + insertions.count + modifications.count
                
                print("Deletions: \(deletions)\nInsertions: \(insertions)\nModif: \(modifications)\n-------")
            case .error(let error):
                fatalError("\(error)")
            }
        })
        
        messageStorage = MessageStorage(messages: self.messages, delegate: self)
        
        service.addInitValues()
    }
    

    @IBAction func addRandom(_ sender: Any) {
        service.addRandomMessage()
//        service.attemptToAddDuplicate()
//        service.addDuplicateArary()
    }
    
    @IBAction func removeLast(_ sender: Any) {
//        service.removeLastMessage()
        service.removeAll()
    }

    var messageStorage: MessageStorage!
    @IBAction func containsCheck(_ sender: Any) {
//        if chat.messages.contains(where: { $0.sortValue == 123 }) {
//            print("check")
//        }
    }
    @IBAction func filterCheck(_ sender: Any) {
//        let first = chat.messages.first(where: { $0.sortValue == 123 })
//        let arr = Array(chat.messages).filter { $0.sortValue < 10 }
//        print("filtered")
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return messageStorage.sections.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageStorage.sections[section].messages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let text = messageStorage.sections[indexPath.section].messages?[indexPath.row].sortValue ?? 99999999
        cell.textLabel?.text = "\(text)"
        
        return cell
    }
    
}

extension ViewController: MessageStorageDelegate {
    
    func messageStorage(_ messageStorage: MessageStorage,
                        deletionIndexPaths: [IndexPath],
                        insertionIndexPaths: [IndexPath],
                        modificationIndexPaths: [IndexPath]) {
        tableView.beginUpdates()
        tableView.deleteRows(at: deletionIndexPaths, with: .automatic)
        tableView.insertRows(at: insertionIndexPaths, with: .automatic)
        tableView.reloadRows(at: modificationIndexPaths, with: .automatic)
        tableView.endUpdates()
    }
    
}
