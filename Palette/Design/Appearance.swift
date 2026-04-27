import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return L10n.t("System", "시스템")
        case .light: return L10n.t("Light", "라이트")
        case .dark: return L10n.t("Dark", "다크")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#if canImport(UIKit)
extension AppearanceMode {
    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    func applyToWindows() {
        let style = uiStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
                Self.applyStyleToPresentationChain(style, from: window.rootViewController)
            }
        }
    }

    private static func applyStyleToPresentationChain(_ style: UIUserInterfaceStyle,
                                                      from vc: UIViewController?) {
        var current = vc
        while let c = current {
            c.overrideUserInterfaceStyle = style
            current = c.presentedViewController
        }
    }
}
#endif
