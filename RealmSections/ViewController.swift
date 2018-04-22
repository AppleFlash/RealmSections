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
    
    private var notification: NotificationToken?
    private var paggingMessages: Results<Message>!
    private var allMessages: Results<Message>!
    
    lazy var chat: Chat = {
        let realm = try! Realm()
        return realm.objects(Chat.self).first!
    }()
    
    private var page: Int = 0
    private let prefetchDistance: Int = 2
    private let pageSize: Int = 10
    private var isLoading: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        service.addInitValues()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        allMessages = try! Realm().objects(Message.self).filter("chatId == %@", "0").sorted(byKeyPath: "sortValue", ascending: true)
        paggingMessages = chat.paggingMessages.sorted(byKeyPath: "sortValue", ascending: true)
        notification = paggingMessages.observe({ (changes) in
            switch changes {
            case .initial(let messages):
                self.messageStorage = MessageStorage(messages: messages, delegate: self)
                self.tableView.reloadData()
            case .update(let messages, let deletions, let insertions, let modifications):
                self.messageStorage.expectedCount = deletions.count + insertions.count + modifications.count
                if self.messageStorage.sections.isEmpty, !insertions.isEmpty {
                    self.messageStorage = MessageStorage(messages: messages, delegate: self)
                }
                print("Deletions: \(deletions)\nInsertions: \(insertions)\nModif: \(modifications)\n-------")
            case .error(let error):
                fatalError("\(error)")
            }
        })
        
        fetchNextPage()
    }
    
    private func fetchNextPage() {
        guard !isLoading else {
            return
        }
        
        isLoading = true
        var messages = [Message]()
        messages.reserveCapacity(pageSize)
        
        let allMessagesCount = allMessages.count
        for offset in (pageSize * page)..<(pageSize * (page + 1)) {
            guard offset < allMessagesCount - 1 else {
                break
            }
            
            messages.append(allMessages[offset])
        }
        
        page += 1
        service.add(messages: messages)
        isLoading = false
    }

    @IBAction func addRandom(_ sender: Any) {
        fetchNextPage()
//        service.addRandomMessage()
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
    
    deinit {
        notification?.invalidate()
        service.removePaggingMessages()
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return messageStorage?.sections.count ?? 0
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
        return messageStorage.sections[section].messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let text = messageStorage.sections[indexPath.section].messages[indexPath.row].sortValue
        cell.textLabel?.text = "\(text)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.section == tableView.numberOfSections - 1,
//            tableView.numberOfRows(inSection: indexPath.section) - indexPath.row <= prefetchDistance {
//            fetchNextPage()
//        }
    }
    
}

extension ViewController: MessageStorageDelegate {
    
    func messageStorageInitialSections(_ messageStorage: MessageStorage) {
        tableView.reloadData()
    }
    
    func messageStorageDidUpdateMessages(_ messageStorage: MessageStorage,
                                         deletionIndexSet: IndexSet,
                                         insertionIndexSet: IndexSet,
                                         modificationIndexSet: IndexSet,
                                         deletionIndexPaths: [IndexPath],
                                         insertionIndexPaths: [IndexPath],
                                         modificationIndexPaths: [IndexPath]) {
        tableView.beginUpdates()
        tableView.deleteSections(deletionIndexSet, with: .automatic)
        tableView.insertSections(insertionIndexSet, with: .automatic)
        tableView.reloadSections(modificationIndexSet, with: .automatic)
        tableView.deleteRows(at: deletionIndexPaths, with: .automatic)
        tableView.insertRows(at: insertionIndexPaths, with: .automatic)
        tableView.reloadRows(at: modificationIndexPaths, with: .automatic)
        tableView.endUpdates()

    }
    
}
