import CoreText
import SwiftUI

/// Registers the bundled Familjen Grotesk and DM Sans files once per process.
enum PortalFonts {
    private static let isRegistered: Bool = {
        let urls = (Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        return !urls.isEmpty
    }()

    static func register() {
        _ = isRegistered
    }
}

/// Type scale. Every style scales with Dynamic Type relative to a system text style.
enum Typography {
    // MARK: Headings — Familjen Grotesk
    static var screenTitle: Font { heading(.bold, 24, .title2) }
    static var section: Font { heading(.semibold, 18, .title3) }
    static var cardTitle: Font { heading(.semibold, 15, .headline) }
    static var statValue: Font { heading(.bold, 20, .title3) }

    // MARK: Body — DM Sans
    static var body: Font { body(.regular, 15, .body) }
    static var bodyMedium: Font { body(.medium, 15, .body) }
    static var button: Font { body(.semibold, 15, .body) }
    static var buttonSmall: Font { body(.semibold, 13, .subheadline) }
    static var toastTitle: Font { body(.semibold, 14, .subheadline) }
    static var secondary: Font { body(.regular, 13, .subheadline) }
    static var label: Font { body(.semibold, 12, .caption) }
    static var chip: Font { body(.medium, 12, .caption) }
    static var caption: Font { body(.medium, 11, .caption2) }
    static var price: Font { body(.bold, 12, .caption) }

    private enum Weight { case regular, medium, semibold, bold }

    private static func heading(_ weight: Weight, _ size: CGFloat, _ style: Font.TextStyle) -> Font {
        PortalFonts.register()
        let name = weight == .bold ? "FamiljenGrotesk-Bold" : "FamiljenGrotesk-SemiBold"
        return .custom(name, size: size, relativeTo: style)
    }

    private static func body(_ weight: Weight, _ size: CGFloat, _ style: Font.TextStyle) -> Font {
        PortalFonts.register()
        let name = switch weight {
        case .regular: "DMSans-Regular"
        case .medium: "DMSans-Medium"
        case .semibold: "DMSans-SemiBold"
        case .bold: "DMSans-Bold"
        }
        return .custom(name, size: size, relativeTo: style)
    }
}
