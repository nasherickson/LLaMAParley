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

// Keep track of models we've already warmed in this process
fileprivate var warmedModels = Set<String>()

fileprivate func warmUpModelIfNeeded(_ model: String, using urls: [URL]) async {
    guard !warmedModels.contains(model) else { return }

    // Longer timeouts just for warmup
    let cfg = URLSessionConfiguration.default
    cfg.timeoutIntervalForRequest = 60
    cfg.timeoutIntervalForResource = 75
    let session = URLSession(configuration: cfg)

    for warmURL in urls {
        var req = URLRequest(url: warmURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "prompt": " ",
            "stream": false,
            "keep_alive": "30m"
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            _ = try await session.data(for: req)
            warmedModels.insert(model)
            print("OLLAMA warmup complete for \(model) on \(warmURL.absoluteString)")
            return
        } catch {
            print("OLLAMA warmup on \(warmURL.absoluteString) failed → \(error.localizedDescription)")
            continue
        }
    }
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

    await warmUpModelIfNeeded(model, using: candidateURLs(for: "generate"))

    func makeSession(long: Bool) -> URLSession {
        let cfg = URLSessionConfiguration.default
        if long {
            cfg.timeoutIntervalForRequest = 60
            cfg.timeoutIntervalForResource = 75
        } else {
            cfg.timeoutIntervalForRequest = 8
            cfg.timeoutIntervalForResource = 12
        }
        return URLSession(configuration: cfg)
    }

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
                    "stream": false,
                    "keep_alive": "30m"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } else {
                let body: [String: Any] = [
                    "model": model,
                    "prompt": prompt,
                    "stream": false,
                    "keep_alive": "30m"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            }

            var attemptError: Error?
            for attempt in 0..<2 {
                let long = (attempt == 1)
                let session = makeSession(long: long)
                do {
                    let (data, response) = try await session.data(for: request)

                    if let http = response as? HTTPURLResponse, http.statusCode == 499 {
                        throw URLError(.timedOut)
                    }

                    if useChat {
                        if let reply = try? JSONDecoder().decode(ChatResp.self, from: data).message?.content {
                            return reply
                        }
                    } else {
                        if let reply = try? JSONDecoder().decode(GenerateResp.self, from: data).response {
                            return reply
                        }
                    }

                    if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let err = obj["error"] as? String {
                        throw NSError(domain: "OllamaAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: err])
                    }

                    throw NSError(domain: "OllamaAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response payload"]) 
                } catch {
                    attemptError = error
                    print("OLLAMA request to \(url) \(long ? "(retry-long)" : "(short)") failed →", error.localizedDescription)
                    continue
                }
            }
            lastError = attemptError
            continue
        } catch {
            print("OLLAMA request to \(url) failed →", error.localizedDescription)
            lastError = error
            continue
        }
    }

    // If we got here, every candidate failed
    throw lastError ?? URLError(.cannotConnectToHost)
}
