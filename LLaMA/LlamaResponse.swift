//
//  LlamaResponse.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//
//
//  LlamaResponse.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//

import Foundation

/// A simple struct to parse responses from the local Llama server.
/// You can expand this if you want more structured data later.
struct LlamaResponse: Codable {
    let model: String?
    let response: String?
    let done: Bool?
    let text: String?
    
    var combinedText: String {
        return response ?? text ?? ""
    }
}
