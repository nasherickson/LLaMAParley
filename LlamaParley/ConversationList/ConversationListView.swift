//
//  ConversationListView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]
    var onSelect: (Conversation) -> Void
    
    var body: some View {
        List(conversations, id: \.id) { convo in
            Button {
                onSelect(convo)
            } label: {
                VStack(alignment: .leading) {
                    Text(convo.title)
                        .font(.headline)
                    Text(convo.conversationDescription.isEmpty ? "No description yet" : convo.conversationDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if conversations.isEmpty {
                let mockConversation = Conversation(title: "Mock Chat", conversationDescription: "Just testing things.")
                modelContext.insert(mockConversation)
                modelContext.insert(Message(text: "This is a preloaded assistant message.", isUser: false, conversation: mockConversation))
                modelContext.insert(Message(text: "Here’s a user reply in the mock convo!", isUser: true, conversation: mockConversation))
                try? modelContext.save()
            }
        }
    }
}
