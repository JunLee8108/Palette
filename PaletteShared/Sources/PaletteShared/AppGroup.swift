import Foundation

public enum AppGroup {
    public static let identifier = "group.com.jun.Palette"

    public static var containerURL: URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            fatalError("Missing App Group container for \(identifier). Enable App Groups capability on the target and add the identifier.")
        }
        return url
    }

    public static var storeURL: URL {
        containerURL.appendingPathComponent("Palette.sqlite")
    }
}
