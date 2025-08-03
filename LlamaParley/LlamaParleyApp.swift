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
    @State private var ollamaStatus: String = "Checking Ollama..."

    init() {
        #if DEBUG
        Task { @MainActor in
            let context = sharedModelContainer.mainContext
            let existing = try? context.fetch(FetchDescriptor<Conversation>())
            DevSeeder.seedConversations(context: context, existing: existing ?? [])
        }
        #endif
    }
    
    func checkOllamaConnection() async -> String {
        for urlString in Config.ollamaURLs {
            if let url = URL(string: urlString) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let response = String(data: data, encoding: .utf8) ?? "No string"
                    print("✅ Ollama response from \(urlString):", response)
                    return "✅ Ollama connected via \(urlString)"
                } catch {
                    print("❌ Ollama test failed for \(urlString):", error.localizedDescription)
                }
            }
        }
        return "❌ Ollama not reachable"
    }

    var body: some Scene {
        WindowGroup {
            VStack {
                Text(ollamaStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                RootView()
                    .modelContainer(sharedModelContainer)
            }
            .onAppear {
                Task {
                    ollamaStatus = await checkOllamaConnection()
                }
            }
        }
    }
}
