//
//  Reflection.swift
//  Llamora
//
//  Created by Nash Erickson on 7/28/25.
//

//
//  Reflection.swift
//  Llamora
//
//  Created by Nash Erickson on [date].
//

import Fluent
import Vapor

final class Reflection: Model, Content {
    static let schema = "reflections"
    
    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: LLaMAUser

    @Field(key: "summary")
    var summary: String

    @Field(key: "commits_count")
    var commitsCount: Int

    @Field(key: "lines_changed")
    var linesChanged: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(userID: UUID, summary: String, commitsCount: Int, linesChanged: Int) {
        self.$user.id = userID
        self.summary = summary
        self.commitsCount = commitsCount
        self.linesChanged = linesChanged
    }
}
