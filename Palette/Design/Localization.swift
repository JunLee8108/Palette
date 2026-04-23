import Foundation

enum L10n {
    static var isKorean: Bool {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ko")
    }

    static func t(_ en: String, _ ko: String) -> String {
        isKorean ? ko : en
    }
}
