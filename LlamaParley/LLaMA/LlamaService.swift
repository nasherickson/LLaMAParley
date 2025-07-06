//
//  LlamaService.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//

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
    private let endpoint = URL(string: "http://localhost:11434/api/generate")!
    
    func sendPrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "llama2",   // adjust your model name here
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
                let decoded = try JSONDecoder().decode(LlamaResponse.self, from: data)
                completion(.success(decoded.text))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
