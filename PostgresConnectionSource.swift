//
//  PostgresConnectionSource.swift
//  Llamora
//
//  Created by Nash Erickson on 8/13/25.
//


//
//  PostgresConnectionSource.swift
//  Llamora
//
//  Created by Nash Erickson on 8/13/25.
//

import AsyncKit
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOSSL
import PostgresNIO
import SQLKit
import PostgresKit

/// Connection source for AsyncKit connection pool using PostgresNIO.
public struct PostgresConnectionSource: ConnectionPoolSource {
    public typealias Connection = PostgresConnection

    public let sqlConfiguration: SQLPostgresConfiguration

    private static let idGenerator = NIOLockedValueBox<Int>(0)

    public init(sqlConfiguration: SQLPostgresConfiguration) {
        self.sqlConfiguration = sqlConfiguration
    }

    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<PostgresConnection> {
        let connectionFuture = PostgresConnection.connect(
            on: eventLoop,
            configuration: self.sqlConfiguration.coreConfiguration,
            id: Self.idGenerator.withLockedValue {
                $0 += 1
                return $0
            },
            logger: logger
        )

        if let searchPath = self.sqlConfiguration.searchPath, !searchPath.isEmpty {
            let searchPathString = searchPath.map { "\"\($0)\"" }.joined(separator: ",")
            return connectionFuture.flatMap { conn in
                conn.sql(queryLogLevel: nil)
                    .raw("SET search_path TO \(raw: searchPathString)")
                    .run()
                    .map { _ in conn }
            }
        } else {
            return connectionFuture
        }
    }

    public func closeConnection(
        _ connection: PostgresConnection,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<Void> {
        connection.close()
    }
}

// MARK: - AsyncKit ConnectionPoolItem conformance for PostgresConnection
extension PostgresConnection: ConnectionPoolItem {
    public var isClosed: Bool { self.isClosed }
    public func close() -> EventLoopFuture<Void> { self.close() }
}