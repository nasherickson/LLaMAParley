//
//  LlamaService.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//

import Foundation

private let OLLAMA_BASE_URL = URL(string: "http://minions.local:11434")!

class LlamaService {
    static let shared = LlamaService()
    
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 30
        cfg.waitsForConnectivity = true
        // Deliver completion handlers on the main queue so UI/TTS calls are isolated correctly
        return URLSession(configuration: cfg, delegate: nil, delegateQueue: .main)
    }()
    
    private var chatEndpoint: URL { OLLAMA_BASE_URL.appendingPathComponent("/api/chat") }
    private var tagsEndpoint: URL { OLLAMA_BASE_URL.appendingPathComponent("/api/tags") }
    
    func sendPrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Optional warmup: non-blocking probe to help DNS/socket warmup
        var probe = URLRequest(url: tagsEndpoint)
        probe.timeoutInterval = 2
        session.dataTask(with: probe).resume()

        var request = URLRequest(url: chatEndpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let requestBody: [String: Any] = [
            "model": "llama3.1:8b-instruct-q4_K_M",   // adjust your model name here
            "messages": [["role": "user", "content": prompt]],
            "stream": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "LlamaService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received."])))
                }
                return
            }
            do {
                if let raw = String(data: data, encoding: .utf8) {
                    print("🔍 Ollama stream: \(raw)")
                    
                    let lines = raw.split(separator: "\n")
                    var fullText = ""
                    
                    for line in lines {
                        if let lineData = line.data(using: .utf8),
                           let decoded = try? JSONDecoder().decode(LlamaResponse.self, from: lineData) {
                            fullText += decoded.combinedText
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success(fullText))
                        if UserDefaults.standard.bool(forKey: "isSpeechEnabled") {
                            TextToSpeech.shared.speak(fullText)
                        }
                    }
                } else {
                    print("⚠️ Unable to decode response as UTF-8 string")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "LlamaService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 response."])))
                    }
                }
            } catch {
                print("❌ Decoding failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        task.resume()
    }
}
