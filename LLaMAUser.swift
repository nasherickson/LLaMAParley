//
//  LLaMAUser.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/11/25.
//
// LLaMAUser.swift
import Fluent
import Foundation
import Vapor

final class LLaMAUser: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
    }
}

