import SwiftUI

/// Every color used by the portal. Values come from the web app's `src/app/globals.css`.
/// Views must only use these tokens — never a literal color.
enum Theme {
    // MARK: Surfaces
    static let background = Color(hex: 0xFFFFFF)
    static let surface = Color(hex: 0xF9FAFB)
    static let muted = Color(hex: 0xF6F9FE)
    static let segment = Color(hex: 0xEEF2F8)
    static let fieldLocked = Color(hex: 0xF4F7FC)

    // MARK: Text
    static let foreground = Color(hex: 0x1B2B4B)
    static let foregroundSoft = Color(hex: 0x33486F)
    static let mutedForeground = Color(hex: 0x5A6B8C)
    static let placeholder = Color(hex: 0x7C8DAE)
    static let hint = Color(hex: 0x8A9AB8)
    static let heading = Color(hex: 0x1F3C6E)

    // MARK: Borders
    static let border = Color(hex: 0xE5E7EB)
    static let borderStrong = Color(hex: 0x7C8DAE)

    // MARK: Brand
    static let primary = Color(hex: 0x4379D6)
    static let primarySoft = Color(hex: 0xEEF4FD)
    static let brand = Color(hex: 0x2F6BC4)
    static let brandStrong = Color(hex: 0x2A5FBD)
    static let brandSoft = Color(hex: 0xE3EEFC)
    static let brandDeep = Color(hex: 0x1F4FB5)
    static let brandBorder = Color(hex: 0x9DBBE9)

    // MARK: Image upload
    static let dropzone = Color(hex: 0xF5F8FE)
    static let dropzoneBorder = Color(hex: 0x9DBDEB)

    // MARK: Status
    static let success = Color(hex: 0x1E8A5A)
    static let successSoft = Color(hex: 0xE6F5EC)
    static let warning = Color(hex: 0xD97706)
    static let warningSoft = Color(hex: 0xFDF1E0)
    static let danger = Color(hex: 0xCC3D3D)
    static let dangerSoft = Color(hex: 0xFCE8E8)

    // MARK: Overlays
    static let scrim = Color(hex: 0x0B1530, opacity: 0.34)

    /// Text and icons placed on a brand, warning or danger fill (alias of `background`).
    static let onBrand = background

    // MARK: Shadow tints (used only by `Shadows.swift`)
    static let shadowBlue = Color(hex: 0x3C78CF)
    static let shadowBrand = brand
    static let shadowInk = Color(hex: 0x0F172A)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
