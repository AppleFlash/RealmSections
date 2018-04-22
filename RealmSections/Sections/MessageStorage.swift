//
//  MessageStorage.swift
//  TestProject
//
//  Created by Vladislav Sedinkin on 21.04.18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import RealmSwift

protocol MessageStorageDelegate: class {
    
    func messageStorageDidUpdateMessages(_ messageStorage: MessageStorage,
                                         deletionIndexSet: IndexSet,
                                         insertionIndexSet: IndexSet,
                                         modificationIndexSet: IndexSet,
                                         deletionIndexPaths: [IndexPath],
                                         insertionIndexPaths: [IndexPath],
                                         modificationIndexPaths: [IndexPath])
    
    func messageStorageInitialSections(_ messageStorage: MessageStorage)
    
}

class MessageStorage {
    
    lazy var sections: [Section] = [Section]()
    var expectedCount: Int = 0
    private var count: Int = 0
    
    private var messagesDeleteIndexPaths: [IndexPath] = [IndexPath]()
    private var messagesInsertIndexPaths: [IndexPath] = [IndexPath]()
    private var messagesModifIndexPaths: [IndexPath] = [IndexPath]()
    
    private var sectionsDeleteIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    private var sectionsInsertIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    private var sectionsModifIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    
    private weak var delegate: MessageStorageDelegate!
    private var notification: NotificationToken?
    private var paggingMessages: Results<Message>!
    
    private var sectionDidUpdate: Bool = false
    var messageInSectionWasInit: Bool = false
    
    private var updateSectionsOterwise: Bool {
        return sectionDidUpdate && messageInSectionWasInit
    }
    
    init(messages: Results<Message>, delegate: MessageStorageDelegate) {
        self.delegate = delegate
        
        prepareSections(messages)
    }
    
    private func prepareSections(_ messages: Results<Message>) {
        guard !messages.isEmpty else {
            print("Messages is empty")
            return
        }
        
        paggingMessages = messages
        
        let request = messages.distinct(by: ["sectionIdentifier"]).sorted(byKeyPath: "sectionIdentifier")
        notification = request.observe({ [weak self] (changes) in
            guard let strongSelf = self else {
                return
            }
            switch changes {
            case .initial(let sections):
                strongSelf.initial(sections: sections)
            case .update(let sections, let deletions, let insertions, let modifications):
                strongSelf.update(sections: sections, indexes: deletions, type: .delete)
                strongSelf.update(sections: sections, indexes: insertions, type: .insert)
                strongSelf.update(sections: sections, indexes: modifications, type: .modif)
                strongSelf.sectionDidUpdate = true
            case .error(let error):
                fatalError("\(error)")
            }
        })
    }
    
    private func initial(sections: Results<Message>) {
        sections.forEach { createSection(with: $0.sectionIdentifier) }
        delegate.messageStorageInitialSections(self)
    }
    
    private func update(sections: Results<Message>, indexes: [Int], type: UpdateChatDataType) {
        guard !indexes.isEmpty else {
            print("Update items empty \(type)")
            return
        }
        
        switch type {
        case .delete:
            indexes.forEach {
                sectionsDeleteIndexSet.add($0)
                self.sections.remove(at: $0)
            }
        case .insert:
            indexes.forEach {
                sectionsInsertIndexSet.add($0)
                insertSection(with: sections[$0].sectionIdentifier, at: $0)
            }
        case .modif:
            print("Modif sections \(indexes)")
        }
    }
    
    private func createSection(with date: Int) {
        let section = initSection(with: date)
        sections.append(section)
    }
    
    private func insertSection(with date: Int, at index: Int) {
        let section = initSection(with: date)
        sections.insert(section, at: index)
    }
    
    private func initSection(with date: Int) -> Section {
        return Section(date: date, delegate: self, result: paggingMessages)
    }
    
    deinit {
        notification?.invalidate()
    }
    
}

extension MessageStorage: SectionDelegate {
    
    func section(_ section: Section, updateWith type: UpdateChatDataType, for indexes: [Int]) {
        let sectionIndex = sections.index(where: { $0 == section })!
        let indexPaths = indexes.map { IndexPath(item: $0, section: sectionIndex) }
        switch type {
        case .delete:
            messagesDeleteIndexPaths += indexPaths
        case .insert:
            messagesInsertIndexPaths += indexPaths
        case .modif:
            messagesModifIndexPaths += indexPaths
        }
        
        count += indexes.count
        if count >= expectedCount || updateSectionsOterwise {
            delegate.messageStorageDidUpdateMessages(self,
                                                     deletionIndexSet: sectionsDeleteIndexSet as IndexSet,
                                                     insertionIndexSet: sectionsInsertIndexSet as IndexSet,
                                                     modificationIndexSet: sectionsModifIndexSet as IndexSet,
                                                     deletionIndexPaths: messagesDeleteIndexPaths,
                                                     insertionIndexPaths: messagesInsertIndexPaths,
                                                     modificationIndexPaths: messagesModifIndexPaths)
            sectionsDeleteIndexSet.removeAllIndexes()
            sectionsInsertIndexSet.removeAllIndexes()
            sectionsModifIndexSet.removeAllIndexes()

            messagesDeleteIndexPaths.removeAll()
            messagesInsertIndexPaths.removeAll()
            messagesModifIndexPaths.removeAll()
            expectedCount = 0
            count = 0
            
            sectionDidUpdate = false
            messageInSectionWasInit = false
        }
    }
    
}

