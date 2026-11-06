import SwiftUI
import UIKit

struct ProductCard: View {
    let product: ManagedProduct
    let currency: Currency
    let onEdit: () -> Void
    let onToggleFeatured: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 12) {
                    ProductImageWell(imageUrl: product.imageUrl)
                        .overlay(alignment: .topLeading) {
                            if product.featured { featuredBadge }
                        }
                        .overlay(alignment: .bottomTrailing) { pricePill }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.category)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.brand)
                            .lineLimit(1)
                        Text(product.name)
                            .font(Typography.cardTitle)
                            .foregroundStyle(Theme.foreground)
                            .lineLimit(1)
                        Text(product.description)
                            .font(Typography.secondary)
                            .foregroundStyle(Theme.mutedForeground)
                            .lineLimit(2, reservesSpace: true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Opens the product editor")

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .padding(.top, 12)

            HStack(spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    liveLabel(showsText: true)
                    liveLabel(showsText: false)
                }
                Spacer(minLength: 4)
                IconButton(icon: .edit2, label: "Edit \(product.name)", action: onEdit)
                IconButton(icon: .trash, label: "Delete \(product.name)", tint: Theme.danger, action: onDelete)
            }
            .padding(.trailing, -10)
            .padding(.bottom, -8)
        }
        .padding(14)
        .portalCard()
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button(action: onEdit) {
                Label { Text("Edit") } icon: { PortalIcon.edit2.image }
            }
            Button(action: onToggleFeatured) {
                Label { Text(product.featured ? "Unfeature" : "Feature") } icon: { PortalIcon.star1.image }
            }
            Button(role: .destructive, action: onDelete) {
                Label { Text("Delete") } icon: { PortalIcon.trash.image }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: product.featured ? "Unfeature" : "Feature", onToggleFeatured)
    }

    private var featuredBadge: some View {
        HStack(spacing: 4) {
            Iconsax(.star1Filled, size: 10)
            Text("Featured")
                .font(Typography.caption)
        }
        .foregroundStyle(Theme.onBrand)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Theme.warning, in: Capsule())
        .portalShadow(.button)
        .padding(8)
        .accessibilityHidden(true)
    }

    private var pricePill: some View {
        Text(currency.format(product.price))
            .font(Typography.price)
            .foregroundStyle(Theme.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Theme.background, in: Capsule())
            .portalShadow(.button)
            .padding(8)
            .accessibilityHidden(true)
    }

    private func liveLabel(showsText: Bool) -> some View {
        HStack(spacing: 4) {
            Iconsax(.tickCircle, size: 14)
            if showsText {
                Text("Live")
                    .font(Typography.caption)
                    .fixedSize()
            }
        }
        .foregroundStyle(Theme.success)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live on your website")
    }

    private var accessibilityLabel: String {
        var parts = [product.name, currency.format(product.price), product.category]
        if product.featured { parts.append("Featured") }
        if !product.description.isEmpty { parts.append(product.description) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Images

/// 4:3 image well (radius 12) that aspect-fills and crops. Muted well + Box icon when empty.
struct ProductImageWell: View {
    let imageUrl: String?
    var cornerRadius: CGFloat = 12

    var body: some View {
        Theme.muted
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay { ProductImage(imageUrl: imageUrl) }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Loads `imageUrl` from the web (http/https), from disk (file://, used by the mock upload)
/// or, for the mock seed's relative paths, from the asset catalog by file name.
struct ProductImage: View {
    let imageUrl: String?

    var body: some View {
        switch Source(imageUrl) {
        case .remote(let url):
            AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    placeholder
                } else {
                    ProgressView().tint(Theme.placeholder)
                }
            }
        case .local(let image):
            Image(uiImage: image).resizable().scaledToFill()
        case .none:
            placeholder
        }
    }

    private var placeholder: some View {
        Iconsax(.box, size: 32)
            .foregroundStyle(Theme.placeholder)
    }

    private enum Source {
        case remote(URL)
        case local(UIImage)
        case none

        init(_ imageUrl: String?) {
            guard let imageUrl, !imageUrl.isEmpty else { self = .none; return }
            if let url = URL(string: imageUrl), let scheme = url.scheme?.lowercased() {
                if scheme == "http" || scheme == "https" {
                    self = .remote(url)
                    return
                }
                if url.isFileURL, let image = UIImage(contentsOfFile: url.path(percentEncoded: false)) {
                    self = .local(image)
                    return
                }
            }
            let assetName = ((imageUrl as NSString).lastPathComponent as NSString).deletingPathExtension
            if let image = UIImage(named: assetName) {
                self = .local(image)
            } else {
                self = .none
            }
        }
    }
}

#Preview("Product cards") {
    let products = [
        ManagedProduct(id: "1", name: "Flat white", description: "Double ristretto with silky steamed milk.",
                       price: "3.50", category: "Coffee", imageUrl: "/mock/templates/warm-bold/flat-white.webp", featured: true),
        ManagedProduct(id: "2", name: "Iced palm sugar latte", description: "Espresso, fresh milk and palm sugar.",
                       price: "18000", category: "Cold drinks", imageUrl: nil, featured: false),
    ]
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
        ProductCard(product: products[0], currency: .usd, onEdit: {}, onToggleFeatured: {}, onDelete: {})
        ProductCard(product: products[1], currency: .khr, onEdit: {}, onToggleFeatured: {}, onDelete: {})
    }
    .padding()
    .background(Theme.background)
}
