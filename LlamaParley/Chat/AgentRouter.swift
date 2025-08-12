//
//  AgentRouter.swift
//  Llamora
//
//  Created by Nash Erickson on 8/12/25.
//


final class AgentRouter {
    var activeAgent: Agent = nova
    var registry: [Agent] = [nova, sage]

    func choose(for text: String) -> Agent {
        // Wake word routing
        if let match = registry.first(where: { w in
            if let wake = w.wakeWord?.lowercased(),
               text.lowercased().hasPrefix(wake + " ") { return true }
            return false
        }) {
            return match
        }
        return activeAgent
    }
}