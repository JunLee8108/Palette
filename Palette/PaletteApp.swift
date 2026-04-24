import SwiftUI
import SwiftData
import PaletteShared

@main
struct PaletteApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.make()
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .tint(PaletteTheme.primaryText)
        }
        .modelContainer(sharedModelContainer)
    }
}
