import PhotosUI
import SwiftUI
import UIKit

/// Add / Edit Product sheet.
struct ProductFormSheet: View {
    @State private var form: ProductFormModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isConfirmingDiscard = false
    @FocusState private var focusedField: ProductFormModel.Field?

    let onUpload: @MainActor (Data) async throws -> String
    let onSave: @MainActor (AddProductInput) async throws -> Void
    let onCancel: @MainActor () -> Void

    init(
        product: ManagedProduct?,
        currency: Currency,
        categories: [String],
        suggestedCategory: String? = nil,
        onUpload: @escaping @MainActor (Data) async throws -> String,
        onSave: @escaping @MainActor (AddProductInput) async throws -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
        _form = State(initialValue: ProductFormModel(
            product: product,
            currency: currency,
            categories: categories,
            suggestedCategory: suggestedCategory
        ))
        self.onUpload = onUpload
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let apiError = form.apiError {
                    ErrorBanner(message: apiError)
                        .transition(.opacity)
                }
                imageField
                nameField
                priceField
                categoryField
                descriptionField
                togglesCard
            }
            .padding(20)
            .disabled(form.isSaving)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) { footer }
        .animation(.easeOut(duration: 0.2), value: form.apiError)
        .presentationDetents([.large])
        .presentationCornerRadius(24)
        .interactiveDismissDisabled(form.isDirty || form.isSaving)
        .confirmationDialog(
            "Discard changes?",
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard changes", role: .destructive, action: onCancel)
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Your changes to this product haven't been saved.")
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            pickerItem = nil
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        form.imageError = "This photo couldn't be opened. Try another one."
                        return
                    }
                    await form.useImage(data: data, upload: onUpload)
                } catch {
                    form.imageError = "This photo couldn't be opened. Try another one."
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { image in
                guard let data = image.preparedForUpload() else { return }
                Task { await form.useImage(data: data, upload: onUpload) }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            IconTile(icon: form.isEditing ? .edit2 : .add)
            VStack(alignment: .leading, spacing: 2) {
                Text(form.isEditing ? "Edit Product" : "Add New Product")
                    .font(Typography.section)
                    .foregroundStyle(Theme.foreground)
                    .accessibilityAddTraits(.isHeader)
                Text(form.isEditing ? "Update product information in your live catalog."
                                    : "Add an item to your storefront catalog.")
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.mutedForeground)
            }
        }
    }

    // MARK: Image

    private var imageField: some View {
        FormField(
            label: "Product image",
            hint: "PNG, JPG or WebP, max 5 MB.",
            error: form.imageError
        ) {
            VStack(spacing: 12) {
                imagePreview
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { imageButtons }
                    VStack(alignment: .leading, spacing: 4) { imageButtons }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Theme.dropzone, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.dropzoneBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        Group {
            if let preview = form.previewImage {
                Theme.muted
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay { Image(uiImage: preview).resizable().scaledToFill() }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if form.imageUrl != nil {
                ProductImageWell(imageUrl: form.imageUrl)
            } else {
                VStack(spacing: 8) {
                    Iconsax(.gallery, size: 28)
                        .foregroundStyle(Theme.placeholder)
                    Text("Add a product photo")
                        .font(Typography.secondary)
                        .foregroundStyle(Theme.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
            }
        }
        .overlay {
            if form.isUploading {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.background.opacity(0.75))
                    VStack(spacing: 8) {
                        ProgressView().tint(Theme.primary)
                        Text("Uploading…")
                            .font(Typography.label)
                            .foregroundStyle(Theme.foregroundSoft)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(form.hasImage ? "Product photo" : "No product photo")
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var imageButtons: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, preferredItemEncoding: .compatible) {
            HStack(spacing: 6) {
                Iconsax(.gallery, size: 16)
                Text("Choose photo")
            }
        }
        .buttonStyle(.portal(.secondary, size: .small))
        .disabled(form.isUploading)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button {
                isShowingCamera = true
            } label: {
                HStack(spacing: 6) {
                    Iconsax(.camera, size: 16)
                    Text("Take photo")
                }
            }
            .buttonStyle(.portal(.secondary, size: .small))
            .disabled(form.isUploading)
        }

        if form.hasImage {
            Button {
                form.removeImage()
            } label: {
                HStack(spacing: 6) {
                    Iconsax(.trash, size: 16)
                    Text("Remove")
                }
                .foregroundStyle(Theme.danger)
            }
            .buttonStyle(.portal(.ghost, size: .small))
            .disabled(form.isUploading)
        }
    }

    // MARK: Fields

    private var nameField: some View {
        FormField(label: "Product name", isRequired: true, error: form.visibleError(for: .name)) {
            InputContainer(isFocused: focusedField == .name, hasError: form.visibleError(for: .name) != nil) {
                TextField("", text: $form.name, prompt: prompt("e.g. Matcha Basque Cheesecake"))
                    .focused($focusedField, equals: .name)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .price }
                    .accessibilityLabel("Product name, required")
            }
        }
        .onChange(of: form.name) { form.touch(.name) }
    }

    private var priceField: some View {
        FormField(
            label: "Price",
            isRequired: true,
            hint: "Prices are shown in \(form.currency.rawValue).",
            error: form.visibleError(for: .price)
        ) {
            InputContainer(isFocused: focusedField == .price, hasError: form.visibleError(for: .price) != nil) {
                HStack(spacing: 6) {
                    Text(form.currency.symbol)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.mutedForeground)
                        .accessibilityHidden(true)
                    TextField("", text: $form.price, prompt: prompt(form.currency.pricePlaceholder))
                        .keyboardType(form.currency == .khr ? .numberPad : .decimalPad)
                        .focused($focusedField, equals: .price)
                        .accessibilityLabel("Price in \(form.currency.rawValue), required")
                }
            }
        }
        .onChange(of: form.price) { _, newValue in
            form.touch(.price)
            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
            if cleaned != newValue { form.price = cleaned }
        }
    }

    private var categoryField: some View {
        FormField(label: "Category", isRequired: true, error: form.visibleError(for: .category)) {
            VStack(alignment: .leading, spacing: 8) {
                if !form.categories.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(form.categories, id: \.self) { category in
                            Chip(title: category, isSelected: form.isChipSelected(category), style: .choice) {
                                form.selectCategory(category)
                            }
                        }
                    }
                }
                InputContainer(
                    isFocused: focusedField == .newCategory,
                    hasError: form.visibleError(for: .category) != nil
                ) {
                    TextField("", text: $form.newCategory, prompt: prompt("Or type a new category…"))
                        .focused($focusedField, equals: .newCategory)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .description }
                        .accessibilityLabel("New category")
                }
            }
        }
        .onChange(of: form.newCategory) { form.touch(.category) }
    }

    private var descriptionField: some View {
        FormField(label: "Short description") {
            VStack(alignment: .trailing, spacing: 4) {
                InputContainer(isFocused: focusedField == .description) {
                    TextField(
                        "",
                        text: $form.description,
                        prompt: prompt("Freshly baked in small batches with premium ingredients…"),
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .description)
                    .accessibilityLabel("Short description")
                }
                Text("\(form.description.count)/\(ProductFormModel.descriptionLimit)")
                    .font(Typography.caption)
                    .foregroundStyle(form.description.count >= ProductFormModel.descriptionLimit ? Theme.warning : Theme.hint)
                    .monospacedDigit()
                    .accessibilityLabel("\(form.description.count) of \(ProductFormModel.descriptionLimit) characters")
            }
        }
        .onChange(of: form.description) { _, newValue in
            if newValue.count > ProductFormModel.descriptionLimit {
                form.description = String(newValue.prefix(ProductFormModel.descriptionLimit))
            }
        }
    }

    private var togglesCard: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: .star1,
                iconColor: Theme.warning,
                title: "Feature on homepage",
                detail: "Show this product in your website's featured section.",
                isOn: $form.featured
            )
            Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 12)
            toggleRow(
                icon: .flash,
                iconColor: Theme.brand,
                title: "Publish to website now",
                detail: "Update your live website right after saving.",
                isOn: $form.autoDeploy
            )
        }
        .padding(14)
        .background(Theme.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func toggleRow(icon: PortalIcon, iconColor: Color, title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(alignment: .top, spacing: 10) {
                Iconsax(icon, size: 20)
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.foreground)
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }
            }
        }
        .tint(Theme.brand)
        .frame(minHeight: 44)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            PrimaryButton(title: "Cancel", variant: .ghost) {
                if form.isDirty {
                    isConfirmingDiscard = true
                } else {
                    onCancel()
                }
            }
            .disabled(form.isSaving)

            Spacer(minLength: 0)

            PrimaryButton(
                title: form.isSaving ? "Saving…" : (form.isEditing ? "Save Changes" : "Add Product"),
                isLoading: form.isSaving
            ) {
                focusedField = nil
                Task { await form.save(using: onSave) }
            }
            .disabled(!form.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Theme.background)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private func prompt(_ text: String) -> Text {
        Text(text).foregroundStyle(Theme.placeholder)
    }
}

// MARK: - Form model

@MainActor
@Observable
final class ProductFormModel {
    enum Field: Hashable { case name, price, category, newCategory, description }

    static let descriptionLimit = 160
    static let maxImageBytes = 5 * 1024 * 1024

    let product: ManagedProduct?
    let currency: Currency
    let categories: [String]

    var name: String
    var price: String
    var selectedCategory: String?
    var newCategory = ""
    var description: String
    var featured: Bool
    var autoDeploy = true

    var imageUrl: String?
    var previewImage: UIImage?
    var isUploading = false
    var imageError: String?

    var isSaving = false
    var apiError: String?
    private var touched: Set<Field> = []
    private let initialInput: AddProductInput

    init(product: ManagedProduct?, currency: Currency, categories: [String], suggestedCategory: String?) {
        self.product = product
        self.currency = currency
        self.categories = categories
        self.name = product?.name ?? ""
        self.price = product?.price ?? ""
        self.selectedCategory = product?.category ?? suggestedCategory
        self.description = product?.description ?? ""
        self.featured = product?.featured ?? false
        self.imageUrl = product?.imageUrl
        self.initialInput = AddProductInput(
            name: product?.name ?? "",
            description: product?.description ?? "",
            price: product?.price ?? "",
            category: product?.category ?? suggestedCategory ?? "",
            imageUrl: product?.imageUrl,
            featured: product?.featured ?? false,
            autoDeploy: true
        )
        // A product whose category isn't in the list yet shows it in the text field.
        if let category = product?.category, !categories.contains(category) {
            self.selectedCategory = nil
            self.newCategory = category
        }
    }

    var isEditing: Bool { product != nil }
    var hasImage: Bool { previewImage != nil || imageUrl != nil }

    // MARK: Validation

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Enter a product name." }
        if trimmed.count > 80 { return "Keep the name under 80 characters." }
        return nil
    }

    var priceError: String? {
        let text = price.trimmingCharacters(in: .whitespaces)
        if text.isEmpty { return "Enter a price." }
        let isNumeric = text.allSatisfy { $0.isASCII && ($0.isNumber || $0 == ".") }
            && text.filter { $0 == "." }.count <= 1
        guard isNumeric, let value = Decimal(string: text, locale: Currency.posix) else {
            return "Enter a price like \(currency.pricePlaceholder)."
        }
        if value <= 0 { return "Price must be greater than 0." }
        let decimals = text.split(separator: ".", omittingEmptySubsequences: false).dropFirst().first?.count ?? 0
        if decimals > currency.fractionDigits {
            return currency == .khr ? "KHR prices can't have decimals." : "Use at most 2 decimal places."
        }
        return nil
    }

    var categoryError: String? {
        resolvedCategory.isEmpty ? "Choose a category or type a new one." : nil
    }

    var resolvedCategory: String {
        let typed = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty {
            // Reuse the existing spelling when the owner types a category that already exists.
            return categories.first { $0.localizedCaseInsensitiveCompare(typed) == .orderedSame } ?? typed
        }
        return selectedCategory ?? ""
    }

    var isValid: Bool { nameError == nil && priceError == nil && categoryError == nil }
    var canSave: Bool { isValid && !isUploading && !isSaving }
    var isDirty: Bool { makeInput(normalizingPrice: false) != initialInput }

    func touch(_ field: Field) { touched.insert(field) }

    func visibleError(for field: Field) -> String? {
        guard touched.contains(field) else { return nil }
        return switch field {
        case .name: nameError
        case .price: priceError
        case .category, .newCategory: categoryError
        case .description: nil
        }
    }

    // MARK: Category

    func isChipSelected(_ category: String) -> Bool {
        newCategory.trimmingCharacters(in: .whitespaces).isEmpty && selectedCategory == category
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
        newCategory = ""
        touch(.category)
    }

    // MARK: Image

    func useImage(data: Data, upload: @MainActor (Data) async throws -> String) async {
        imageError = nil
        guard ImageFormat(data: data) != nil else {
            imageError = "Use a PNG, JPG or WebP image."
            return
        }
        guard data.count <= Self.maxImageBytes else {
            let megabytes = Double(data.count) / 1_048_576
            imageError = "This image is \(megabytes.formatted(.number.precision(.fractionLength(1)))) MB. Choose one that is 5 MB or smaller."
            return
        }
        let previousUrl = imageUrl
        previewImage = UIImage(data: data)
        isUploading = true
        defer { isUploading = false }
        do {
            imageUrl = try await upload(data)
        } catch {
            previewImage = nil
            imageUrl = previousUrl
            imageError = error.portalMessage
        }
    }

    func removeImage() {
        previewImage = nil
        imageUrl = nil
        imageError = nil
    }

    // MARK: Save

    func makeInput(normalizingPrice: Bool = true) -> AddProductInput {
        var priceText = price.trimmingCharacters(in: .whitespaces)
        if normalizingPrice, let value = Decimal(string: priceText, locale: Currency.posix) {
            priceText = currency.normalize(value)
        }
        return AddProductInput(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceText,
            category: resolvedCategory,
            imageUrl: imageUrl,
            featured: featured,
            autoDeploy: normalizingPrice ? autoDeploy : true
        )
    }

    func save(using onSave: @MainActor (AddProductInput) async throws -> Void) async {
        touched.formUnion([.name, .price, .category])
        guard canSave else { return }
        isSaving = true
        apiError = nil
        defer { isSaving = false }
        do {
            try await onSave(makeInput())
        } catch {
            apiError = error.portalMessage
        }
    }
}

// MARK: - Helpers

/// Allowed upload formats, detected from the file's leading bytes.
enum ImageFormat {
    case png, jpeg, webp

    init?(data: Data) {
        let bytes = [UInt8](data.prefix(12))
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            self = .png
        } else if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            self = .jpeg
        } else if bytes.count >= 12, bytes[0..<4] == [0x52, 0x49, 0x46, 0x46], bytes[8..<12] == [0x57, 0x45, 0x42, 0x50] {
            self = .webp
        } else {
            return nil
        }
    }
}

extension UIImage {
    /// JPEG data scaled so the longest side is at most 2000px, keeping camera photos under 5 MB.
    func preparedForUpload(maxDimension: CGFloat = 2000) -> Data? {
        let longest = max(size.width, size.height)
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.85)
    }
}

/// Camera capture via UIImagePickerController.
struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Wraps chips onto as many lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

// MARK: - Previews

#Preview("Add") {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProductFormSheet(
            product: nil,
            currency: .usd,
            categories: ["Coffee", "Cold drinks", "Pastries", "Cakes"],
            onUpload: { _ in "/mock/templates/warm-bold/flat-white.webp" },
            onSave: { _ in },
            onCancel: {}
        )
    }
}

#Preview("Edit") {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProductFormSheet(
            product: ManagedProduct(
                id: "1", name: "Cinnamon bun",
                description: "Baked every morning with brown butter and a cream cheese glaze.",
                price: "2.75", category: "Pastries",
                imageUrl: "/mock/templates/warm-bold/cinnamon-bun.webp", featured: true
            ),
            currency: .usd,
            categories: ["Coffee", "Cold drinks", "Pastries", "Cakes"],
            onUpload: { _ in "" },
            onSave: { _ in throw APIError(message: "A product named \"Cinnamon bun\" already exists in your catalog.") },
            onCancel: {}
        )
    }
}

#Preview("KHR") {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProductFormSheet(
            product: nil,
            currency: .khr,
            categories: [],
            onUpload: { _ in "" },
            onSave: { _ in },
            onCancel: {}
        )
    }
}
