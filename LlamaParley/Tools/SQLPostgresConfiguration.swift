//
//  SQLPostgresConfiguration.swift
//  Llamora
//
//  Created by Nash Erickson on 8/13/25.
//

import Foundation
import NIOCore
import NIOSSL
import PostgresNIO

/// Provides configuration paramters for establishing PostgreSQL database connections.
public struct SQLPostgresConfiguration: Sendable {
    /// IANA-assigned port number for PostgreSQL
    public static var ianaPortNumber: Int { 5432 }

    // See `PostgresNIO.PostgresConnection.Configuration`.
    public var coreConfiguration: PostgresConnection.Configuration

    /// Optional `search_path` to set on new connections.
    public var searchPath: [String]?

    /// Create a SQLPostgresConfiguration from a string containing a properly formatted URL.
    public init(url: String) throws {
        guard let url = URL(string: url) else {
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLStringErrorKey: url])
        }
        try self.init(url: url)
    }

    /// Create a SQLPostgresConfiguration from a properly formatted URL.
    public init(url: URL) throws {
        guard let comp = URLComponents(url: url, resolvingAgainstBaseURL: true), let username = comp.user else {
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
        }
        func decideTLSConfig(from queryItems: [URLQueryItem], defaultMode: String) throws -> PostgresConnection.Configuration.TLS {
            switch queryItems.last(where: { ["tlsmode", "sslmode", "ssl", "tls"].contains($0.name.lowercased()) })?.value ?? defaultMode {
            case "verify-full", "verify-ca", "require":
                return try .require(.init(configuration: .makeClientConfiguration()))
            case "prefer", "allow", "true":
                return try .prefer(.init(configuration: .makeClientConfiguration()))
            case "disable", "false":
                return .disable
            default:
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
            }
        }
        switch comp.scheme {
        case "postgres", "postgres+tcp", "postgresql", "postgresql+tcp":
            guard let hostname = comp.host, !hostname.isEmpty else {
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
            }
            self.init(
                hostname: hostname, port: comp.port ?? Self.ianaPortNumber,
                username: username, password: comp.password,
                database: url.lastPathComponent.isEmpty ? nil : url.lastPathComponent,
                tls: try decideTLSConfig(from: comp.queryItems ?? [], defaultMode: "prefer")
            )
        case "postgres+uds", "postgresql+uds":
            guard (comp.host?.isEmpty ?? true || comp.host == "localhost"), comp.port == nil, !comp.path.isEmpty, comp.path != "/" else {
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
            }
            var coreConfig = PostgresConnection.Configuration(unixSocketPath: comp.path, username: username, password: comp.password, database: comp.fragment)
            coreConfig.tls = try decideTLSConfig(from: comp.queryItems ?? [], defaultMode: "disable")
            self.init(coreConfiguration: coreConfig)
        default:
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
        }
    }

    /// Create a SQLPostgresConfiguration for connecting to a server with a hostname and optional port.
    public init(
        hostname: String, port: Int = Self.ianaPortNumber,
        username: String, password: String? = nil,
        database: String? = nil,
        tls: PostgresConnection.Configuration.TLS
    ) {
        self.init(coreConfiguration: .init(host: hostname, port: port, username: username, password: password, database: database, tls: tls))
    }

    /// Create a SQLPostgresConfiguration for connecting to a server through a UNIX domain socket.
    public init(
        unixDomainSocketPath: String,
        username: String, password: String? = nil,
        database: String? = nil
    ) {
        self.init(coreConfiguration: .init(unixSocketPath: unixDomainSocketPath, username: username, password: password, database: database))
    }

    /// Create a SQLPostgresConfiguration for establishing a connection to a server over a preestablished Channel.
    public init(
        establishedChannel: any Channel,
        username: String, password: String? = nil,
        database: String? = nil
    ) {
        self.init(coreConfiguration: .init(establishedChannel: establishedChannel, username: username, password: password, database: database))
    }

    public init(
        coreConfiguration: PostgresConnection.Configuration,
        searchPath: [String]? = nil
    ) {
        self.coreConfiguration = coreConfiguration
        self.searchPath = searchPath
    }
}
