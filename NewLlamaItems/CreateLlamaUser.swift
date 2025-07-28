//
//  CreateLlamaUser.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/11/25.
//
// CreateLLaMAUser.swift
import Fluent

struct CreateLLaMAUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
