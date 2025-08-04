import Foundation

struct ChatMessage {
    let role: String
    let content: String
}

func sendMessage(prompt: String, model: String = "llama3:70b", previousMessages: [ChatMessage] = []) async throws -> String {
    print("Sending to Ollama, model: \(model), prompt: \(prompt)")
    
    func buildOllamaURL(for endpoint: String) -> URL? {
        for base in Config.ollamaURLs {
            let candidate = base.replacingOccurrences(of: "/api/tags", with: "/api/\(endpoint)")
            if let url = URL(string: candidate) {
                return url
            }
        }
        return nil
    }

    // Build URL
    guard let url = buildOllamaURL(for: "generate") else {
        throw URLError(.badURL)
    }
    
    // Build request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body: [String: Any] = [
        "model": model,
        "prompt": prompt,
        "previousMessages": previousMessages.map { ["role": $0.role, "content": $0.content] }
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Send request
    let (data, _) = try await URLSession.shared.data(for: request)
    
    // Decode response
    let response = try JSONDecoder().decode([String: String].self, from: data)
    if let reply = response["reply"] {
        return reply
    } else {
        throw NSError(domain: "OllamaAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
}
