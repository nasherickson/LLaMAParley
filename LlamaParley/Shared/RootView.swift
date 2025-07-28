//
//  RootView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//
import Swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedConversationID: UUID?
    @State private var showingNewConversation = false
    @Query var conversations : [Conversation]


    var body: some View {
        GeometryReader { geo in
            ZStack {
                GeometricBackground()
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ConversationToolbar {
                            // Create a new conversation
                            let conversation = Conversation(title: "New Chat", conversationDescription: "", details: "", messages: [])
                            // Insert into model context
                            modelContext.insert(conversation)
                            // Attempt to save changes
                            try? modelContext.save()
                            // Debug print statements for insertion and current state
                            print("Inserted conversation: \(conversation.id) \(conversation.title)")
                            print("Current conversations after insert: \(conversations.map { $0.title })")
                            // Update selected conversation
                            selectedConversationID = conversation.id
                        }
                        List(selection: $selectedConversationID) {
                            ForEach(conversations) { convo in
                                VStack(alignment: .leading) {
                                    Text(convo.title)
                                        .font(.headline)
                                    Text(convo.details.isEmpty ? "No description yet" : convo.details)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(width: geo.size.width * 0.33)

                    ConversationDivider()

                    if conversations.isEmpty {
                        EmptyConversationView()
                            .frame(width: geo.size.width * 0.67)
                    } else if let convoID = selectedConversationID,
                              let convo = conversations.first(where: { $0.id == convoID }) {
                        ChatView(conversation: convo)
                            .frame(width: geo.size.width * 0.67)
                    } else {
                        Text("Select a conversation")
                            .frame(width: geo.size.width * 0.67)
                    }
                }
            }
        }
    }
}
