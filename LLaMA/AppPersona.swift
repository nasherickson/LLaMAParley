import Foundation

//
//  AppPersona.swift
//  Llamora
//
//  Created by Nash Erickson on 8/13/25.
//


// MARK: - Launch Greeting Utilities

struct AppPersona {
    static var displayName: String {
        let v = UserDefaults.standard.string(forKey: "displayName")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return v?.isEmpty == false ? v! : "there"
    }
    
    /// Keep this updated whenever the user completes notable work or closes a chat.
    static var lastWorkSummary: String? {
        get { UserDefaults.standard.string(forKey: "lastWorkSummary") }
        set { UserDefaults.standard.setValue(newValue, forKey: "lastWorkSummary") }
    }
}

extension LlamaService {
    /// "Good morning, Archer — shall we pick up where we left off?"
    func buildTimeOfDayGreeting(now: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: now)
        let prefix: String
        switch hour {
        case 5..<12:  prefix = "Good morning"
        case 12..<17: prefix = "Good afternoon"
        case 17..<22: prefix = "Good evening"
        default:      prefix = "Hey"
        }
        return "\(prefix), \(AppPersona.displayName) — shall we pick up where we left off?"
    }

    /// Produces the *assistant* message to seed a new chat UI.
    func launchGreetingMessage() -> String {
        if let summary = AppPersona.lastWorkSummary?.trimmingCharacters(in: .whitespacesAndNewlines), summary.isEmpty == false {
            return "\(buildTimeOfDayGreeting())\n\nLast time, you were working on: \(summary)."
        } else {
            return buildTimeOfDayGreeting()
        }
    }

    /// Optional: a tiny nudge to your model so it’s context-primed without asking a question.
    func launchPrimingPrompt() -> String {
        let summary = AppPersona.lastWorkSummary ?? "No recorded summary."
        return """
        The user just opened the app. Respond briefly and helpfully.
        If appropriate, offer to resume the last task.

        Last recorded work summary:
        \(summary)
        """
    }
}
