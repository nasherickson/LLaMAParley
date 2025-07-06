//
//  Messeges.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var text: String
    var timestamp: Date
    var isUser: Bool
    var conversationID: UUID
    // new!
    init(text: String, isUser: Bool, conversationID: UUID) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.isUser = isUser
        self.conversationID = conversationID
    }
}

