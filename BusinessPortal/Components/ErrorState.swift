import SwiftUI

/// Full-width error with the API message and a "Try again" button.
struct ErrorState: View {
    var title = "Couldn't load products"
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            IconTile(icon: .danger, foreground: Theme.danger, background: Theme.dangerSoft, size: 48)
                .padding(.bottom, 4)
            Text(title)
                .font(Typography.section)
                .foregroundStyle(Theme.foreground)
            Text(message)
                .font(Typography.secondary)
                .foregroundStyle(Theme.mutedForeground)
                .frame(maxWidth: 320)
            PrimaryButton(title: "Try again", icon: .refresh2, variant: .secondary, action: retry)
                .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
}

/// Inline banner for API errors inside forms and sheets.
struct ErrorBanner: View {
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Iconsax(.danger, size: 18)
                .foregroundStyle(Theme.danger)
            VStack(alignment: .leading, spacing: 6) {
                Text(message)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let action {
                    PrimaryButton(title: actionTitle, icon: .refresh2, variant: .destructive, size: .small, action: action)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.dangerSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

#Preview("Error state") {
    VStack(spacing: 24) {
        ErrorState(message: "We couldn't load your products. Check your connection and try again.") {}
        ErrorBanner(message: "A product named \"Flat white\" already exists.")
        ErrorBanner(message: "Build failed.", actionTitle: "Try again") {}
    }
    .padding()
    .background(Theme.background)
}
