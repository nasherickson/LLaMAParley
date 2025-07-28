//
//  LlamaParleyApp.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/2/25.
//

import SwiftUI
import SwiftData

let sharedModelContainer = try! ModelContainer(for: Conversation.self)

@main
struct LlamaParleyApp: App {
    @Environment(\.modelContext) var context
    @Query var conversations: [Conversation]

    init() {
        #if DEBUG
        Task {
            let context = sharedModelContainer.mainContext
            let existing = try? context.fetch(FetchDescriptor<Conversation>())
            DevSeeder.seedConversations(context: context, existing: existing ?? [])
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
