//
//  Section.swift
//  TestProject
//
//  Created by Vladislav Sedinkin on 21.04.18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import RealmSwift

enum UpdateChatDataType {
    case delete, insert, modif
}

protocol SectionDelegate: class {
    
    var messageInSectionWasInit: Bool {get set}
    
    func section(_ section: Section, updateWith type: UpdateChatDataType, for indexes: [Int])
    
}

class Section {
    
    private(set) var messages: Results<Message>!
    private(set) var date: Int
    private var notificationToken: NotificationToken?
    private weak var delegate: SectionDelegate!
    
    init(date: Int, delegate: SectionDelegate, result: Results<Message>) {
        self.date = date
        self.delegate = delegate
        self.messages = result
        
        prepareMessages(for: result)
        setNotificationBlock()
    }
    
    private func prepareMessages(for result: Results<Message>) {
        messages = result.filter("sectionIdentifier == %@", date).sorted(byKeyPath: "sortValue", ascending: true)
    }
    
    private func setNotificationBlock() {
        notificationToken = messages.observe({ [weak self] (changes) in
            guard let strongSelf = self else {
                return
            }
            
            switch changes {
            case .initial(let messages):
                print("Initial in section \(strongSelf.date)")
                strongSelf.delegate.messageInSectionWasInit = true
                strongSelf.delegate.section(strongSelf, updateWith: .insert, for: [])
//                var indexes = [Int]()
//                indexes.reserveCapacity(messages.underestimatedCount)
//                for index in 0..<messages.count - 1 {
//                    indexes.append(index)
//                }
//                guard !indexes.isEmpty else {
//                    return
//                }
//                strongSelf.delegate.section(strongSelf, updateWith: .insert, for: indexes)
            case .update(_, let deletions, let insertions, let modifications):
                print("Update in section: \(strongSelf.date).\nDelete at \(deletions)\nInsert at \(insertions)\nModif at \(modifications)")
                if !deletions.isEmpty {
                    strongSelf.delegate.section(strongSelf, updateWith: .delete, for: deletions)
                }
                if !insertions.isEmpty {
                    strongSelf.delegate.section(strongSelf, updateWith: .insert, for: insertions)
                }
                if !modifications.isEmpty {
                    strongSelf.delegate.section(strongSelf, updateWith: .modif, for: modifications)
                }
            case .error(let error):
                fatalError("\(error)")
            }
        })
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
}

extension Section: Equatable {
    
    static func ==(lhs: Section, rhs: Section) -> Bool {
        return lhs.date == rhs.date
    }
    
}
