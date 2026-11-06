import SwiftUI

/// Label, control, then either an inline error (danger) or a hint.
struct FormField<Content: View>: View {
    let label: String
    var isRequired = false
    var hint: String?
    var error: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                Text(label)
                    .foregroundStyle(Theme.foreground)
                if isRequired {
                    Text("*")
                        .foregroundStyle(Theme.danger)
                        .accessibilityLabel("required")
                }
            }
            .font(Typography.label)
            .accessibilityElement(children: .combine)

            content

            if let error {
                Text(error)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            } else if let hint {
                Text(hint)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.hint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .animation(.easeOut(duration: 0.15), value: error)
    }
}

/// Input chrome: radius 12, 1pt border, 44pt min height, 2pt primary ring when focused.
struct InputContainer<Content: View>: View {
    var isFocused = false
    var hasError = false
    var isLocked = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .font(Typography.body)
            .foregroundStyle(Theme.foreground)
            .tint(Theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(isLocked ? Theme.fieldLocked : Theme.background,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private var borderColor: Color {
        if isFocused { return Theme.primary }
        if hasError { return Theme.danger }
        return Theme.border
    }
}

/// "Search products…" field with a clear button.
struct SearchField: View {
    @Binding var text: String
    var placeholder = "Search products…"
    @FocusState private var isFocused: Bool

    var body: some View {
        InputContainer(isFocused: isFocused) {
            HStack(spacing: 8) {
                Iconsax(.searchNormal1, size: 18)
                    .foregroundStyle(Theme.placeholder)
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.placeholder))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search products")
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Iconsax(.closeCircle, size: 18)
                            .foregroundStyle(Theme.placeholder)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
        }
    }
}

#Preview("Form fields") {
    @Previewable @State var text = ""
    VStack(spacing: 20) {
        SearchField(text: $text)
        FormField(label: "Product name", isRequired: true, error: "Enter a product name.") {
            InputContainer(hasError: true) { TextField("e.g. Matcha Basque Cheesecake", text: $text) }
        }
        FormField(label: "Price", isRequired: true, hint: "Prices are in USD.") {
            InputContainer(isFocused: true) { TextField("4.50", text: $text) }
        }
    }
    .padding()
    .background(Theme.background)
}
