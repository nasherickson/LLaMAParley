//
//  LlamaSetting.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//

//
//  LlamaSetting.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//

import Foundation

/// User-adjustable or app-wide configuration for the local Llama engine.
struct LlamaSetting {
    static let shared = LlamaSetting()
    
    /// The name of the LLM model to call (as loaded in Ollama)
    let modelName: String = "llama2"

    /// Sampling temperature, 0 = deterministic, higher = more random
    let temperature: Double = 0.7
    
    // Add other parameters here if you like later
}
