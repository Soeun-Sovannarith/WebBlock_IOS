import SwiftUI

/// Website status: "Live" in success colors, "Offline" in muted colors.
struct StatusPill: View {
    let isLive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLive ? Theme.success : Theme.placeholder)
                .frame(width: 6, height: 6)
            Text(isLive ? "Live" : "Offline")
                .font(Typography.label)
        }
        .foregroundStyle(isLive ? Theme.success : Theme.mutedForeground)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isLive ? Theme.successSoft : Theme.muted, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isLive ? "Website is live" : "Website is offline")
    }
}

/// Website name + status pill shown at the top of every portal section.
struct PortalHeader: View {
    let siteName: String?
    let isLive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(siteName ?? "Your website")
                .font(Typography.cardTitle)
                .foregroundStyle(Theme.heading)
                .lineLimit(1)
                .redacted(reason: siteName == nil ? .placeholder : [])
            if siteName != nil {
                StatusPill(isLive: isLive)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Status") {
    VStack(spacing: 16) {
        StatusPill(isLive: true)
        StatusPill(isLive: false)
        PortalHeader(siteName: "Riverside Bakehouse", isLive: true)
        PortalHeader(siteName: nil, isLive: false)
    }
    .padding()
    .background(Theme.background)
}
