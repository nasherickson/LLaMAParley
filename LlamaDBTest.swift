//
//  LlamaDBTest.swift
//  Llamora
//
//  Created by Nash Erickson on 7/23/25.

import Foundation
import Fluent
import Vapor

func testLlamaDB() async {
    let dbService = LlamaDatabaseService()

    do {
        try await dbService.configure()
        guard let db = dbService.getDatabase() else {
            print("❌ Couldn't get a database connection.")
            return
        }

        let testUser = LLaMAUser(username: "TestUser-Archer", email: "archer@example.com")
        try await testUser.save(on: db)
        print("✅ Saved new user.")

        let users = try await LLaMAUser.query(on: db).all()
        print("📦 All Users:")
        for user in users {
            print("- \(user.id?.uuidString ?? "No ID") | \(user.username)")
        }

    } catch {
        print("🔥 DB Test Failed: \(error)")
    }
}
