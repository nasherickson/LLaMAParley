//
//  ConversationListView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftUI
import SwiftData

struct ConversationListView: View {
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
    }
}
