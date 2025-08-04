import Foundation
import Fluent
import FluentPostgresDriver
import Logging
import NIO
import NIOSSL

final class LlamaDatabaseService {
    private var db: Database?

    func configure() async throws {
        // 1. Create a thread pool and start it (only needed for command-line or custom apps)
        let threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let sslContext = try! NIOSSLContext(configuration: .makeClientConfiguration())
        // 2. Set up Fluent's database config (use SQLPostgresConfiguration for FluentPostgresDriver)
        let postgresConfig = SQLPostgresConfiguration(
            hostname: "192.168.0.152",
            port: 5432,
            username: "nasherickson",
            password: "ApolloCow1!",
            database: "llama_parley",
            tls: .prefer(sslContext)
        )

        // 3. Create and configure the Fluent Databases container
        let databases = Databases(threadPool: threadPool, on: eventLoopGroup.next())
        databases.use(.postgres(configuration: postgresConfig), as: .psql)

        // 4. Define and add your migrations
        var migrations = Migrations()
        migrations.add(CreateLLaMAUser())

        // 5. Run migrations
        let migrator = Migrator(
            databases: databases,
            migrations: migrations,
            logger: Logger(label: "MigrationLogger"),
            on: eventLoopGroup.next()
        )

        try await migrator.setupIfNeeded()
        try await migrator.prepareBatch()

        // 6. Save DB instance (if needed)
        self.db = databases.database(.psql, logger: Logger(label:"AppLogger"),
                                     on: eventLoopGroup.next()
        )

        print(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask))
    }

    func getDatabase() -> Database? {
        return db
    }
}
