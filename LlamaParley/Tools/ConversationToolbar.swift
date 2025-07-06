//
//  ConversationToolbar.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//


import SwiftUI

struct ConversationToolbar: View {
    var onNewConversation: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                onNewConversation()
            }) {
                Label("New Chat", systemImage: "plus.bubble.fill")
            }
            .buttonStyle(.bordered)
            Spacer()
            // Future: Add other toolbar items here
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
}
