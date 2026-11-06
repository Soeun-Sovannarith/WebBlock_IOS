import SwiftUI

struct Toast: Identifiable, Equatable, Sendable {
    enum Style: Sendable { case success, error }

    let id = UUID()
    let style: Style
    let title: String
    let message: String

    static func success(_ title: String, _ message: String) -> Toast {
        Toast(style: .success, title: title, message: message)
    }

    static func error(_ title: String, _ message: String) -> Toast {
        Toast(style: .error, title: title, message: message)
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 12) {
            Iconsax(toast.style == .success ? .tickCircle : .danger, size: 22)
                .foregroundStyle(toast.style == .success ? Theme.success : Theme.danger)
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(Typography.toastTitle)
                    .foregroundStyle(Theme.foreground)
                Text(toast.message)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.mutedForeground)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: 480)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        }
        .portalShadow(.float)
        .accessibilityElement(children: .combine)
    }
}

/// Shows `toast` at the top of the view, slides it in over 200ms and hides it after 4 seconds.
private struct ToastHost: ViewModifier {
    @Binding var toast: Toast?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(toast: toast)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onTapGesture { self.toast = nil }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Dismisses the message")
                    .task(id: toast.id) {
                        AccessibilityNotification.Announcement("\(toast.title). \(toast.message)").post()
                        try? await Task.sleep(for: .seconds(4))
                        if self.toast?.id == toast.id {
                            self.toast = nil
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: toast)
    }
}

extension View {
    func portalToast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastHost(toast: toast))
    }
}

#Preview("Toasts") {
    VStack(spacing: 16) {
        ToastView(toast: .success("Product added", "Flat white has been added to the catalog."))
        ToastView(toast: .error("Couldn't remove product", "This product no longer exists."))
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Theme.surface)
}
