//
//  Conversation.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftData
import Foundation
@Model
final class Conversation: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var conversationDescription: String
    var details: String
    var messages: [Message]
    var createdAt: Date
    var lastWorkSummary: String?
    var lastActiveAt: Date?
    
    init(title: String,
         conversationDescription: String,
         details: String = "",
         messages: [Message] = [],
         createdAt: Date = Date(),
         lastWorkSummary: String? = nil,
         lastActiveAt: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.conversationDescription = conversationDescription
        self.details = details
        self.messages = messages
        self.createdAt = createdAt
        self.lastWorkSummary = lastWorkSummary
        self.lastActiveAt = lastActiveAt ?? createdAt
    }
}
