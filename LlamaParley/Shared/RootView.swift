import SwiftUI

struct ConversationsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var conversations: [Conversation] = []
    @State private var selectedConversation: Conversation?
    @State private var hasLaunched = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedConversation) {
                ForEach(conversations) { conversation in
                    NavigationLink(value: conversation) {
                        ConversationRowView(conversation: conversation)
                    }
                }
                .onDelete(perform: deleteConversations)
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newConversation()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                if !hasLaunched {
                    let newConvo = Conversation(title: "Welcome Back", conversationDescription: "")
                    let greeting = LlamaService.shared.launchGreetingMessage()
                    let message = Message(text: greeting, isUser: false, conversation: newConvo)
                    newConvo.messages.append(message)
                    modelContext.insert(newConvo)
                    modelContext.insert(message)
                    conversations.append(newConvo)
                    selectedConversation = newConvo
                    hasLaunched = true
                }
                // TODO: Fetch conversations from your data source.
            }
        } detail: {
            if let selectedConversation {
                ChatView(conversation: selectedConversation)
            } else {
                Text("Select a conversation")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func newConversation() {
        let conversation = Conversation(title: "", conversationDescription: "")
        modelContext.insert(conversation)
        conversations.append(conversation)
        selectedConversation = conversation
    }

    private func deleteConversations(offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            modelContext.delete(conversation)
        }
        conversations.remove(atOffsets: offsets)
    }
}

