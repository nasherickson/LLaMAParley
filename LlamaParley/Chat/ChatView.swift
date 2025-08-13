import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    var conversation: Conversation
    
    @State private var newMessageText: String = ""
    
    var body: some View {
        VStack {
            List {
                ForEach(conversation.messages, id: \.id) { message in
                    Text(message.text)
                }
            }
            HStack {
                TextField("Type a message", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.title)
    }
    
    private func sendMessage() {
        let message = Message(text: newMessageText, isUser: true, conversation: conversation)
        newMessageText = ""
        
        // Update the conversation's messages in the model context
        modelContext.insert(message)
        conversation.messages.append(message)
        modelContext.insert(conversation)
    }
}

