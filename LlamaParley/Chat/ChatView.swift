//
//  ChatView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftUI
import SwiftData

struct ChatView: View {
    var conversation: Conversation

    @State private var messageText: String = ""
    @Environment(\.modelContext) private var modelContext

    @Query private var messages: [Message]

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        if message.conversationID == conversation.id {
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                        .frame(maxWidth: 250, alignment: .leading)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            HStack {
                TextField("Type a message…", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    func sendMessage() {
        let newMessage = Message(
            text: messageText,
            isUser: true,
            conversationID: conversation.id
        )
        modelContext.insert(newMessage)
        messageText = ""
    }
}
