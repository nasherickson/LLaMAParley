import SwiftUI
import SwiftData

struct RootView: View {
    @State private var showSettings = false
    @State private var selectedConversation: Conversation?
    @Environment(\.modelContext) private var modelContext
    @Query var conversations: [Conversation]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Settings button at top right with high zIndex
                HStack {
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .padding(8)
                    }
                    .accessibilityLabel("Settings")
                    
                }
                .padding(.top, 8)
                .padding(.trailing, 12)
                .zIndex(10)

                // Background and main content
                GeometricBackground()
                    .edgesIgnoringSafeArea(.all)

                if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("No conversations yet.")
                            .font(.title2)
                            .foregroundStyle(.ultraThinMaterial)
                        Text("Tap the + button to start a new conversation.")
                            .font(.body)
                            .foregroundColor(.clear)
                        Spacer()
                    }
                    .padding()
                } else {
                    HStack(spacing: 0) {
                        ConversationListView(conversations: conversations, onSelect: { convo in
                            selectedConversation = convo
                        })
                        .frame(width: geo.size.width * 0.3)
                        .background(Color(UIColor.systemGroupedBackground))
                        .border(Color.gray.opacity(0.02), width: 1)

                        Divider()

                        VStack(spacing: 0) {
                            ConversationToolbar(onNewConversation: {
                                // Add logic to create a new Conversation and select it
                                let newConvo = Conversation(title: "New Chat", conversationDescription: "")
                                modelContext.insert(newConvo)
                                selectedConversation = newConvo
                            })
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.3))
                            .border(Color.gray.opacity(0.02), width: 1)

                            if let selectedConversation = selectedConversation {
                                ChatView(conversation: selectedConversation)
                                    .padding()
                                    .background(.ultraThinMaterial.opacity(0.1))
                            } else {
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SpeechSettingsPanel()
        }
    }
}

