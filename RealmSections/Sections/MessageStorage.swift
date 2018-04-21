//
//  MessageStorage.swift
//  TestProject
//
//  Created by Vladislav Sedinkin on 21.04.18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import RealmSwift

protocol MessageStorageDelegate: class {
    
    func messageStorage(_ messageStorage: MessageStorage,
                        deletionIndexPaths: [IndexPath],
                        insertionIndexPaths: [IndexPath],
                        modificationIndexPaths: [IndexPath])
    
}

class MessageStorage {
    
    lazy var sections: [Section] = [Section]()
    var expectedCount: Int = 0
    private var count: Int = 0
    private var deleteIndexPaths: [IndexPath] = [IndexPath]()
    private var insertIndexPaths: [IndexPath] = [IndexPath]()
    private var modifIndexPaths: [IndexPath] = [IndexPath]()
    
    private weak var delegate: MessageStorageDelegate!
    
    init(messages: Results<Message>, delegate: MessageStorageDelegate) {
        self.delegate = delegate
        
        prepareSections(messages)
    }
    
    private func prepareSections(_ messages: Results<Message>) {
        guard !messages.isEmpty else {
            print("Messages is empty")
            return
        }
        
        createSection(with: messages.first!.sortValue)
        
        var lastDigit: Int = Int(messages.first!.sortValue / 10)
        for mesIndex in 1..<messages.count {
            let sortValue = messages[mesIndex].sortValue
            let digit = Int(sortValue / 10)
            if digit > lastDigit {
                createSection(with: sortValue)
                lastDigit = digit
            }
        }
    }
    
    private func createSection(with date: Int) {
        let section = Section(date: date, delegate: self)
        sections.append(section)
    }
    
    func updateSections(_ messages: Results<Message>, inserIndexes: [Int]) {
        let sortValues = inserIndexes.map { messages[$0].sortValue }
        let digitValues = sortValues.map { Int($0 / 10) }
        guard digitValues.count != sections.count else {
            return
        }
    }
    
}

extension MessageStorage: SectionDelegate {
    
    func section(_ section: Section, updateWith type: UpdateSectionType, for indexes: [Int]) {
        let sectionIndex = sections.index(where: { $0 == section })!
        let indexPaths = indexes.map { IndexPath(item: $0, section: sectionIndex) }
        switch type {
        case .delete:
            deleteIndexPaths += indexPaths
        case .insert:
            insertIndexPaths += indexPaths
        case .modif:
            modifIndexPaths += indexPaths
        }
        
        count += indexes.count
        if count >= expectedCount {
            delegate.messageStorage(self,
                                    deletionIndexPaths: deleteIndexPaths,
                                    insertionIndexPaths: insertIndexPaths,
                                    modificationIndexPaths: modifIndexPaths)
            deleteIndexPaths.removeAll()
            insertIndexPaths.removeAll()
            modifIndexPaths.removeAll()
            expectedCount = 0
            count = 0
        }
    }
    
}

