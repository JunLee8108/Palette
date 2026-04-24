import Foundation
import SwiftData

public enum SharedModelContainer {
    public static func make(readOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([ColorEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: !readOnly,
            groupContainer: .identifier(AppGroup.identifier)
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
