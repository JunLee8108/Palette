import SwiftUI
import SwiftData
import PaletteShared

@main
struct PaletteApp: App {
    @AppStorage("palette.appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue

    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.make()
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(PaletteTheme.primaryText)
                #if canImport(UIKit)
                .onAppear { appearance.applyToWindows() }
                #endif
        }
        .modelContainer(sharedModelContainer)
    }
}
