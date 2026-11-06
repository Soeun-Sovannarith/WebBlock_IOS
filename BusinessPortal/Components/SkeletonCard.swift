import SwiftUI

/// Loading placeholder with the same size as `ProductCard`.
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.muted)
                .aspectRatio(4 / 3, contentMode: .fit)
            VStack(alignment: .leading, spacing: 8) {
                bar(width: 0.35, height: 10)
                bar(width: 0.8, height: 14)
                bar(width: 1, height: 10)
                bar(width: 0.6, height: 10)
            }
            Rectangle().fill(Theme.border).frame(height: 1)
            HStack {
                bar(width: 0.3, height: 10)
                Spacer()
                Circle().fill(Theme.muted).frame(width: 24, height: 24)
                Circle().fill(Theme.muted).frame(width: 24, height: 24)
            }
            .frame(height: 32)
        }
        .padding(14)
        .shimmer()
        .portalCard()
        .accessibilityHidden(true)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Theme.muted)
                .frame(width: proxy.size.width * width)
        }
        .frame(height: height)
    }
}

/// Soft highlight that sweeps across muted placeholders. Static when Reduce Motion is on.
private struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, Theme.background.opacity(0.7), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

#Preview("Skeleton") {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
        ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
    }
    .padding()
    .background(Theme.background)
}
