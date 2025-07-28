//
//  DevSeeder.swift
//  Llamora
//
//  Created by Nash Erickson on 7/23/25.
//

import SwiftData
import Foundation

enum DevSeeder {
    static func seedConversations(context: ModelContext, existing: [Conversation]) {
        guard existing.isEmpty else {
            print("🟡 Conversations already exist. Skipping seed.")
            return
        }

        let mock1 = Conversation(title: "Mock Chat 1", conversationDescription: "First test conversation", details: "mock chat 1", messages: [])
        let mock2 = Conversation(title: "Mock Chat 2", conversationDescription: "Second test conversation", details: "mock chat 2", messages: [])

        context.insert(mock1)
        context.insert(mock2)

        do {
            try context.save()
            print("✅ Dev seed complete")
        } catch {
            print("❌ Failed to seed dev conversations: \(error)")
        }
    }
}
