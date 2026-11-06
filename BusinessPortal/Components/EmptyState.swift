import SwiftUI

/// Centered icon tile, title, message and optional action. `dashed` draws the dashed card
/// used for an empty catalog.
struct EmptyState: View {
    let icon: PortalIcon
    let title: String
    let message: String
    var actionTitle: String?
    var actionIcon: PortalIcon?
    var dashed = false
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            IconTile(icon: icon, size: 48)
                .padding(.bottom, 4)
            Text(title)
                .font(Typography.section)
                .foregroundStyle(Theme.foreground)
            Text(message)
                .font(Typography.secondary)
                .foregroundStyle(Theme.mutedForeground)
                .frame(maxWidth: 320)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, icon: actionIcon, action: action)
                    .padding(.top, 8)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background {
            if dashed {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.border, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
        }
    }
}

#Preview("Empty state") {
    VStack(spacing: 24) {
        EmptyState(
            icon: .box,
            title: "No products yet",
            message: "Add your first product to show it on your website.",
            actionTitle: "Add Product",
            actionIcon: .add,
            dashed: true
        ) {}
        EmptyState(
            icon: .searchNormal1,
            title: "No products found",
            message: "No products matched \"matcha\". Try another search or category."
        )
    }
    .padding()
    .background(Theme.background)
}
