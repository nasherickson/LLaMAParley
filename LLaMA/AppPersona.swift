import Foundation

// Make sure PostgresConnectionSource.swift is included in your build target. If error persists, check target membership.

#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(PostgresNIO)
import PostgresNIO
#endif
import AsyncKit

// MARK: - Work Summary Storage & Dictation Protocols

/// Abstract storage so we can swap UserDefaults for a database-backed store easily.
protocol WorkSummaryStore {
    func fetchLastWorkSummary() async throws -> String?
}

/// Default implementation that mirrors current behavior (UserDefaults only).
struct UserDefaultsWorkSummaryStore: WorkSummaryStore {
    func fetchLastWorkSummary() async throws -> String? {
        return UserDefaults.standard.string(forKey: "lastWorkSummary")
    }
}

/// Lightweight dictation hook so the greeting can be spoken when available.
protocol DictationHandler {
    /// Speak the provided text (fire-and-forget is fine). Implementations may enqueue TTS.
    func speak(_ text: String) async
}

// MARK: - Concrete Implementations (Optional Drop-ins)

#if canImport(AVFoundation)
/// AVSpeechSynthesizer-backed dictation that runs on the main thread.
final class AVSpeechDictationHandler: DictationHandler {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String) async {
        await MainActor.run {
            let utt = AVSpeechUtterance(string: text)
            // Keep defaults simple; you can tune voice/rate per persona later.
            utt.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utt)
        }
    }
}
#endif

#if canImport(PostgresNIO)
/// PostgresNIO-backed store. Expects a table like:
///   CREATE TABLE work_summaries (
///     id bigserial PRIMARY KEY,
///     summary text NOT NULL,
///     updated_at timestamptz DEFAULT now()
///   );
/// Adjust the query if your schema differs.
struct PostgresWorkSummaryStore: WorkSummaryStore {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>

    func fetchLastWorkSummary() async throws -> String? {
        try await withCheckedThrowingContinuation { cont in
            pool.withConnection { conn in
                conn.simpleQuery(
                    "SELECT summary FROM work_summaries ORDER BY updated_at DESC NULLS LAST, id DESC LIMIT 1;"
                )
            }.whenComplete { result in
                switch result {
                case .success(let rows):
                    // Grab the first column named or positioned 'summary'.
                    if let first = rows.first {
                        // Try name first, then index 0 as a fallback.
                        let value: String? = first.column("summary")?.string ?? first.columns.first?.string
                        cont.resume(returning: value)
                    } else {
                        cont.resume(returning: nil)
                    }
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
        }
    }
}
#endif

// USAGE EXAMPLE (call site):
// let message = await llamaService.launchGreetingMessage(
//     using: PostgresWorkSummaryStore(pool: myPool),
//     autoDictateWith: AVSpeechDictationHandler()
// )

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
    /// Async version that can pull from a database-backed store and optionally auto-dictate.
    func launchGreetingMessage(
        using store: WorkSummaryStore = UserDefaultsWorkSummaryStore(),
        autoDictateWith dictation: DictationHandler? = nil
    ) async -> String {
        // Try to fetch a more authoritative summary (e.g., DB) first; fall back to UserDefaults via the store.
        let rawSummary: String? = (try? await store.fetchLastWorkSummary())
        let summary = rawSummary?.trimmingCharacters(in: .whitespacesAndNewlines)

        let message: String
        if let s = summary, s.isEmpty == false {
            message = "\(buildTimeOfDayGreeting())\n\nLast time, you were working on: \(s)."
        } else {
            message = buildTimeOfDayGreeting()
        }

        // Fire-and-forget dictation if provided.
        if let d = dictation {
            Task { await d.speak(message) }
        }

        return message
    }

    /// Deprecated: synchronous wrapper retained for current call sites.
    /// Uses UserDefaults-only path and does NOT auto-dictate.
    @available(*, deprecated, message: "Use the async launchGreetingMessage(using:autoDictateWith:) for DB + TTS.")
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

