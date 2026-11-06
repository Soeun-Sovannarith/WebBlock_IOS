import SwiftUI

/// Capsule buttons from the web app: primary, secondary, ghost and destructive.
struct PortalButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, ghost, destructive }
    enum Size {
        case regular, small

        var height: CGFloat { self == .regular ? 40 : 32 }
    }

    var variant: Variant = .primary
    var size: Size = .regular
    var fullWidth = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(size == .regular ? Typography.button : Typography.buttonSmall)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 18)
            .frame(minHeight: size.height)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Capsule().fill(background(pressed: pressed)))
            .overlay {
                if variant == .secondary {
                    Capsule().strokeBorder(Theme.border, lineWidth: 1)
                }
            }
            .portalShadow(shadow(pressed: pressed))
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(Capsule())
            .frame(minHeight: 44)
            .animation(.easeOut(duration: 0.15), value: pressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary, .destructive: Theme.onBrand
        case .secondary: Theme.foreground
        case .ghost: Theme.foregroundSoft
        }
    }

    private func background(pressed: Bool) -> Color {
        switch variant {
        case .primary: Theme.brand
        case .destructive: Theme.danger
        case .secondary: pressed ? Theme.muted : Theme.background
        case .ghost: pressed ? Theme.muted : .clear
        }
    }

    private func shadow(pressed: Bool) -> PortalShadow {
        switch variant {
        case .primary, .destructive: pressed && isEnabled ? .buttonPressed : .button
        case .secondary: .button
        case .ghost: PortalShadow(color: .clear, radius: 0, x: 0, y: 0)
        }
    }
}

extension ButtonStyle where Self == PortalButtonStyle {
    static func portal(
        _ variant: PortalButtonStyle.Variant = .primary,
        size: PortalButtonStyle.Size = .regular,
        fullWidth: Bool = false
    ) -> PortalButtonStyle {
        PortalButtonStyle(variant: variant, size: size, fullWidth: fullWidth)
    }
}

/// Primary capsule button with an optional leading icon and a loading state.
struct PrimaryButton: View {
    let title: String
    var icon: PortalIcon?
    var variant: PortalButtonStyle.Variant = .primary
    var size: PortalButtonStyle.Size = .regular
    var isLoading = false
    var fullWidth = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Theme.onBrand)
                } else if let icon {
                    Iconsax(icon, size: size == .regular ? 18 : 16)
                }
                Text(title)
            }
        }
        .buttonStyle(.portal(variant, size: size, fullWidth: fullWidth))
        .disabled(isLoading)
    }
}

/// A 44×44 icon-only button with a required VoiceOver label.
struct IconButton: View {
    let icon: PortalIcon
    let label: String
    var tint: Color = Theme.foregroundSoft
    var iconSize: CGFloat = 18
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Iconsax(icon, size: iconSize)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview("Buttons") {
    VStack(spacing: 12) {
        PrimaryButton(title: "Add Product", icon: .add) {}
        PrimaryButton(title: "Saving…", isLoading: true) {}
        PrimaryButton(title: "View live site", icon: .exportSquare, variant: .secondary) {}
        PrimaryButton(title: "Cancel", variant: .ghost) {}
        PrimaryButton(title: "Delete", icon: .trash, variant: .destructive, size: .small) {}
        HStack {
            IconButton(icon: .edit2, label: "Edit") {}
            IconButton(icon: .trash, label: "Delete", tint: Theme.danger) {}
        }
    }
    .padding()
    .background(Theme.background)
}
