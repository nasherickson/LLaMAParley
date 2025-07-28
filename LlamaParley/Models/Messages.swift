// Messages.swift

import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var text: String
    var timestamp: Date
    var isUser: Bool
    @Relationship var conversation: Conversation

    init(text: String, isUser: Bool, conversation: Conversation) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.isUser = isUser
        self.conversation = conversation
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

extension Message: Identifiable {}
