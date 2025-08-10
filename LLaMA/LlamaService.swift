//
//  LlamaService.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//

import Foundation

class LlamaService {
    static let shared = LlamaService()
    
    private let session = URLSession.shared
    private var endpoint: URL {
        // Fallback: take the first valid Config URL
        for urlString in Config.ollamaURLs {
            if let url = URL(string: urlString.replacingOccurrences(of: "/api/tags", with: "")) {
                return url
            }
        }
        fatalError("No valid Ollama endpoints in Config.swift")
    }
    
    func sendPrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "llama3.1:8b-instruct-q4_K_M",   // adjust your model name here
            "prompt": prompt
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "LlamaService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received."])))
                return
            }
            do {
                if let raw = String(data: data, encoding: .utf8) {
                    print("🔍 Raw Ollama response: \(raw)")
                    
                    let lines = raw.split(separator: "\n")
                    var fullText = ""
                    
                    for line in lines {
                        if let lineData = line.data(using: .utf8),
                           let decoded = try? JSONDecoder().decode(LlamaResponse.self, from: lineData) {
                            fullText += decoded.combinedText
                        }
                    }
                    
                    completion(.success(fullText))
                    
                    // Speak reply if speech is enabled
                    if UserDefaults.standard.bool(forKey: "isSpeechEnabled") {
                        TextToSpeech.shared.speak(fullText)
                    }
                } else {
                    print("⚠️ Unable to decode response as UTF-8 string")
                    completion(.failure(NSError(domain: "LlamaService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 response."])))
                }
            } catch {
                print("❌ Decoding failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
