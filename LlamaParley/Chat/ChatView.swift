//
//  ChatView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftUI
import SwiftData
import Foundation

struct ChatView: View {
    var conversation: Conversation
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Query private var allMessages: [Message]
    
    var body: some View {
        let messages = allMessages.filter { $0.conversation == conversation }
        let displayMessages = messages.isEmpty ? [
            Message(text: "Hello! This is a mock message.", isUser: false, conversation: conversation),
            Message(text: "Hi there! Just testing rendering.", isUser: true, conversation: conversation)
        ] : messages
        
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(displayMessages) { message in
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
            HStack {
                TextField("Type a message…", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSending)
                Button("Send") {
                    Task { await sendMessage() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending || messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }

    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = Message(
            text: messageText,
            isUser: true,
            conversation: conversation
        )
        modelContext.insert(userMessage)
        let prompt = messageText
        messageText = ""
        isSending = true
        do {
            let messages = allMessages.filter { $0.conversation == conversation }
            let chatHistory = messages.map { ChatMessage(role: $0.isUser ? "user" : "assistant", content: $0.text) }
            let ollamaResponse = try await Llamora.sendMessage(prompt: prompt, previousMessages: chatHistory)
            let assistantMessage = Message(
                text: ollamaResponse,
                isUser: false,
                conversation: conversation
            )
            modelContext.insert(assistantMessage)
        } catch {
            let errorMessage = Message(
                text: "[Error from Ollama: \(error.localizedDescription)]",
                isUser: false,
                conversation: conversation
            )
            modelContext.insert(errorMessage)
        }
        isSending = false
    }
}

