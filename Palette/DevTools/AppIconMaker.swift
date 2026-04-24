import SwiftUI
import PaletteShared
#if canImport(UIKit)
import UIKit
#endif

struct AppIconView: View {
    static let stripes: [Color] = [
        Color(hex: "#E8594A"),
        Color(hex: "#F07D4C"),
        Color(hex: "#F4A74C"),
        Color(hex: "#E8DC6F"),
        Color(hex: "#D96E7C"),
        Color(hex: "#B46FAB"),
        Color(hex: "#9B7EBD"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<Self.stripes.count, id: \.self) { i in
                Self.stripes[i]
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#if DEBUG && canImport(UIKit)
@MainActor
enum AppIconExporter {
    static let size: CGFloat = 1024

    static func writePNG(name: String = "AppIcon-1024.png") -> URL? {
        let renderer = ImageRenderer(content:
            AppIconView().frame(width: size, height: size)
        )
        renderer.scale = 1.0
        guard let image = renderer.uiImage, let data = image.pngData() else { return nil }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
#endif

#Preview("Icon (rounded)") {
    AppIconView()
        .frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 240 * 0.2237, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .padding(40)
}

#Preview("Icon (square source)") {
    AppIconView()
        .frame(width: 512, height: 512)
}
