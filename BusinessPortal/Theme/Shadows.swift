import SwiftUI

/// Blue-tinted shadows from the web app. CSS blur is roughly twice SwiftUI's radius.
struct PortalShadow: Sendable {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = PortalShadow(color: Theme.shadowBlue.opacity(0.05), radius: 6, x: 5, y: 6)
    static let button = PortalShadow(color: Theme.shadowBlue.opacity(0.06), radius: 0.5, x: 0, y: 1)
    static let buttonPressed = PortalShadow(color: Theme.shadowBrand.opacity(0.18), radius: 5, x: 0, y: 4)
    static let float = PortalShadow(color: Theme.shadowBlue.opacity(0.12), radius: 15, x: 0, y: 10)
    static let dialog = PortalShadow(color: Theme.shadowInk.opacity(0.20), radius: 30, x: 0, y: 24)
}

extension View {
    func portalShadow(_ shadow: PortalShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
