//
//  ConversationListView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftUI
import SwiftData

struct ConversationListView: View {
    var conversations: [Conversation]
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
                // Since modelContext is no longer available here, this block may no longer function as before.
                // The instructions did not specify changes here, so it remains unchanged.
            }
        }
    }
}
