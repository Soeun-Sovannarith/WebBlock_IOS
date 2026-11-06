import SwiftUI

/// Capsule chip. `.filter` is used for the category filter row, `.choice` for picking a
/// category inside the product form.
struct Chip: View {
    enum Style { case filter, choice }

    let title: String
    let isSelected: Bool
    var style: Style = .filter
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? Typography.label : Typography.chip)
                .lineLimit(1)
                .foregroundStyle(foreground)
                .padding(.horizontal, 14)
                .frame(minHeight: 32)
                .background(Capsule().fill(background))
                .overlay { Capsule().strokeBorder(border, lineWidth: 1) }
                .frame(minHeight: 44)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }

    private var foreground: Color {
        switch (style, isSelected) {
        case (.filter, true): Theme.onBrand
        case (.choice, true): Theme.brandDeep
        case (.filter, false): Theme.mutedForeground
        case (.choice, false): Theme.foregroundSoft
        }
    }

    private var background: Color {
        switch (style, isSelected) {
        case (.filter, true): Theme.primary
        case (.choice, true): Theme.primarySoft
        case (.filter, false): Theme.muted
        case (.choice, false): Theme.background
        }
    }

    private var border: Color {
        switch (style, isSelected) {
        case (.filter, _): .clear
        case (.choice, true): Theme.brandBorder
        case (.choice, false): Theme.border
        }
    }
}

#Preview("Chips") {
    VStack(alignment: .leading) {
        HStack {
            Chip(title: "All", isSelected: true) {}
            Chip(title: "Coffee", isSelected: false) {}
        }
        HStack {
            Chip(title: "Pastries", isSelected: true, style: .choice) {}
            Chip(title: "Cakes", isSelected: false, style: .choice) {}
        }
    }
    .padding()
    .background(Theme.background)
}
