import Foundation
import SwiftData

enum ATLASMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ATLASchemaV1.self, ATLASchemaV2.self, ATLASchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: ATLASchemaV1.self,
                toVersion: ATLASchemaV2.self
            ),
            .lightweight(
                fromVersion: ATLASchemaV2.self,
                toVersion: ATLASchemaV3.self
            )
        ]
    }
}

enum ModelContainerFactory {
    static let schema = Schema(versionedSchema: ATLASchemaV3.self)

    static func make(
        inMemory: Bool = false,
        storeURL: URL? = nil
    ) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(
                "ATLAS",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                "ATLAS",
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: .none
            )
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: ATLASMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
