import SwiftUI

/// 40×40 rounded tile holding an icon. Defaults to brandSoft / brandStrong.
struct IconTile: View {
    let icon: PortalIcon
    var foreground: Color = Theme.brandStrong
    var background: Color = Theme.brandSoft
    var size: CGFloat = 40

    var body: some View {
        Iconsax(icon, size: size / 2)
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview("Icon tiles") {
    HStack {
        IconTile(icon: .box)
        IconTile(icon: .star1, foreground: Theme.warning, background: Theme.warningSoft)
        IconTile(icon: .tickCircle, foreground: Theme.success, background: Theme.successSoft)
        IconTile(icon: .danger, foreground: Theme.danger, background: Theme.dangerSoft)
    }
    .padding()
    .background(Theme.background)
}
