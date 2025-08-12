//
//  ChatView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/3/25.
//
import SwiftUI
import SwiftData
import Foundation
import AVFoundation

struct ChatView: View {
    var conversation: Conversation
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Query private var allMessages: [Message]
    @State private var isListening: Bool = false
    @State private var dictation = AutoDictationCoordinator()
    private let tts = TTS()
    private var router = AgentRouter()
    
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
                Button {
                    toggleListening()
                } label: {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                }
                .buttonStyle(.bordered)
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
        .onAppear {
            dictation.onFinalizedUtterance = { utterance in
                Task { await sendMessage(utterance) }
            }
        }
    }

    func sendMessage(_ overrideText: String? = nil) async {
        let raw = (overrideText ?? messageText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        let userMessage = Message(
            text: raw,
            isUser: true,
            conversation: conversation
        )
        modelContext.insert(userMessage)
        let prompt = raw
        messageText = ""
        isSending = true
        do {
            let messages = allMessages.filter { $0.conversation == conversation }
            let chatHistory = messages.map { ChatMessage(role: $0.isUser ? "user" : "assistant", content: $0.text) }
            let agent = router.choose(for: prompt)
            let ollamaResponse = try await Llamora.sendMessage(prompt: prompt, model: agent.model, previousMessages: chatHistory)
            let assistantMessage = Message(
                text: ollamaResponse,
                isUser: false,
                conversation: conversation
            )
            modelContext.insert(assistantMessage)
            tts.speak(ollamaResponse, with: agent.voice)
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

    private func toggleListening() {
        if isListening {
            dictation.stop()
            isListening = false
        } else {
            try? dictation.start()
            isListening = true
        }
    }

    private func stripWakeWord(_ text: String, wake: String?) -> String {
        guard let w = wake?.lowercased() else { return text }
        let lower = text.lowercased()
        if lower.hasPrefix(w + " ") { return String(text.dropFirst(w.count + 1)) }
        return text
    }
}

