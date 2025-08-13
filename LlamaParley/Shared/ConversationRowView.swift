import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading) {
            Text(conversation.title)
                .font(.headline)
            Text(conversation.conversationDescription.isEmpty ? "No description yet" : conversation.conversationDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
