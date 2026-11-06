import SwiftUI

/// White card: radius 16, 1pt border, blue card shadow.
struct Card<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .portalCard()
    }
}

extension View {
    func portalCard(cornerRadius: CGFloat = 16) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.background)
                .portalShadow(.card)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        }
    }
}

/// Small stat card used in the products stats row.
struct StatCard: View {
    let icon: PortalIcon
    let iconForeground: Color
    let iconBackground: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            IconTile(icon: icon, foreground: iconForeground, background: iconBackground)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.mutedForeground)
                Text(value)
                    .font(Typography.statValue)
                    .foregroundStyle(Theme.foreground)
            }
            .lineLimit(1)
            .fixedSize()
        }
        .padding(14)
        .frame(minWidth: 150, alignment: .leading)
        .portalCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview("Cards") {
    VStack(spacing: 16) {
        Card {
            Text("Card content")
                .font(Typography.body)
                .foregroundStyle(Theme.foreground)
        }
        StatCard(
            icon: .box,
            iconForeground: Theme.brandStrong,
            iconBackground: Theme.brandSoft,
            label: "Total catalog",
            value: "8"
        )
    }
    .padding()
    .background(Theme.background)
}
