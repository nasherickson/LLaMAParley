import Foundation

struct ChatMessage {
    let role: String
    let content: String
}

func sendMessage(prompt: String, model: String = "llama3:70b", previousMessages: [ChatMessage] = []) async throws -> String {
    print("Sending to Ollama, model: \(model), prompt: \(prompt)")
    
    // Example implementation for sending a message to the Ollama API
    guard let url = URL(string: "http://100.83.122.44:11434/api/generate") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body: [String: Any] = [
        "model": model,
        "prompt": prompt,
        "previousMessages": previousMessages.map { ["role": $0.role, "content": $0.content] }
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode([String: String].self, from: data)
    if let reply = response["reply"] {
        return reply
    } else {
        throw NSError(domain: "OllamaAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
}
