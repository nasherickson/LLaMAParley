import Foundation

enum ModelConfig {
    static var defaultModel: String {
        if let env = ProcessInfo.processInfo.environment["OLLAMA_MODEL"], !env.isEmpty {
            return env
        }
        return UserDefaults.standard.string(forKey: "OLLAMA_MODEL")
            ?? "llama3.1:8b-instruct-q4_K_M"
    }
}

struct ChatMessage {
    let role: String
    let content: String
}

func sendMessage(prompt: String, model: String = ModelConfig.defaultModel, previousMessages: [ChatMessage] = []) async throws -> String {
    print("Sending to Ollama, model: \(model), prompt: \(prompt)")
    
    struct GenerateResp: Decodable { let response: String? }
    struct ChatResp: Decodable {
        struct Msg: Decodable { let role: String?; let content: String }
        let message: Msg?
    }
    
    func candidateURLs(for endpoint: String) -> [URL] {
        // 1) Allow runtime override via UserDefaults key `OLLAMA_URLS` (CSV of full base URLs like http://host:11434/api/tags)
        // 2) Fallback to Config.ollamaURLs
        // 3) Append known Tailscale IPs as last-resort fallbacks
        var bases: [String] = []

        if let overrideCSV = UserDefaults.standard.string(forKey: "OLLAMA_URLS"), !overrideCSV.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            bases = overrideCSV
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        } else {
            bases = Config.ollamaURLs
        }

        // Append user-provided Tailscale IPs as fallbacks (server first)
        let tailscaleFallbacks = [
            "http://100.83.122.44:11434/api/tags",   // Mac mini (server)
            "http://100.113.187.91:11434/api/tags"   // MacBook (client; harmless fallback)
        ]

        // Merge uniquely while preserving order
        var seen = Set<String>()
        var merged: [String] = []
        for s in bases + tailscaleFallbacks {
            if !s.isEmpty, !seen.contains(s) {
                seen.insert(s)
                merged.append(s)
            }
        }

        // Build endpoint URLs
        var urls: [URL] = []
        for base in merged {
            let candidate = base.replacingOccurrences(of: "/api/tags", with: "/api/\(endpoint)")
            if let url = URL(string: candidate) {
                urls.append(url)
            }
        }
        return urls
    }

    // Decide endpoint based on whether we have a conversation
    let useChat = !previousMessages.isEmpty
    let endpoint = useChat ? "chat" : "generate"

    let urls = candidateURLs(for: endpoint)
    print("OLLAMA → candidates:", urls.map { $0.absoluteString })

    // Prepare a short-timeout session so we fail fast instead of hanging
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 8
    config.timeoutIntervalForResource = 12
    let session = URLSession(configuration: config)

    var lastError: Error?

    // Try each candidate until one works
    for url in urls {
        do {
            // Build request per endpoint
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if useChat {
                var messages = previousMessages.map { ["role": $0.role, "content": $0.content] }
                messages.append(["role": "user", "content": prompt])
                let body: [String: Any] = [
                    "model": model,
                    "messages": messages,
                    "stream": false
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } else {
                let body: [String: Any] = [
                    "model": model,
                    "prompt": prompt,
                    "stream": false
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            }

            let (data, _) = try await session.data(for: request)

            if useChat {
                if let reply = try? JSONDecoder().decode(ChatResp.self, from: data).message?.content {
                    return reply
                }
            } else {
                if let reply = try? JSONDecoder().decode(GenerateResp.self, from: data).response {
                    return reply
                }
            }

            // As a fallback, try to parse generic error to improve diagnostics
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = obj["error"] as? String {
                throw NSError(domain: "OllamaAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: err])
            }

            throw NSError(domain: "OllamaAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response payload"])
        } catch {
            print("OLLAMA request to \(url) failed →", error.localizedDescription)
            lastError = error
            continue
        }
    }

    // If we got here, every candidate failed
    throw lastError ?? URLError(.cannotConnectToHost)
}
