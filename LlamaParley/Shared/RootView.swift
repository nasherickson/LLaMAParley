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
    @State private var selectedConversationID: UUID?
    @State private var showingNewConversation = false
    @Query var conversations : [Conversation]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    ConversationToolbar {
                        showingNewConversation = true
                    }
                    List(selection: $selectedConversationID) {
                        ForEach(conversations) { convo in
                            VStack(alignment: .leading) {
                                Text(convo.title)
                                    .font(.headline)
                                Text(convo.details.isEmpty ? "No description yet" : convo.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                    ZStack {
                        GeometricBackground()
                        ChatView(conversation: convo)
                    }
                    .frame(width: geo.size.width * 0.67)
                } else {
                    Text("Select a conversation")
                        .frame(width: geo.size.width * 0.67)
                }
            }
        }
    }
}
