import SwiftUI

struct ProductsView: View {
    @State private var viewModel: ProductsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    init(viewModel: ProductsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Theme.background)
            .refreshable { await viewModel.load() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar { toolbar }
        }
        .task { await viewModel.loadIfNeeded() }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(sheet)
        }
        .alert(
            "Delete \"\(viewModel.pendingDelete?.name ?? "")\"?",
            isPresented: deleteAlertBinding,
            presenting: viewModel.pendingDelete
        ) { product in
            Button("Delete", role: .destructive) {
                Task { await viewModel.confirmDelete(product) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This removes the product from your catalog and updates your live website.")
        }
        .portalToast($viewModel.toast)
        .sensoryFeedback(.success, trigger: viewModel.successFeedback)
        .sensoryFeedback(.warning, trigger: viewModel.warningFeedback)
    }

    // MARK: Header

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Products")
                .font(Typography.screenTitle)
                .foregroundStyle(Theme.primary)
                .accessibilityAddTraits(.isHeader)
            Text("Manage your storefront. Changes are published to your live website.")
                .font(Typography.secondary)
                .foregroundStyle(Theme.mutedForeground)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            PortalHeader(siteName: viewModel.data?.siteName, isLive: viewModel.data?.isLive ?? false)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Button {
                    openURL(viewModel.website.liveURL)
                } label: {
                    Label { Text("View live site") } icon: { PortalIcon.exportSquare.image }
                }
                Button {
                    Task { await viewModel.publishChanges() }
                } label: {
                    Label { Text("Publish changes") } icon: { PortalIcon.flash.image }
                }
                .disabled(viewModel.data == nil)
            } label: {
                Iconsax(.more, size: 22)
                    .foregroundStyle(Theme.foregroundSoft)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("More actions")

            Button {
                viewModel.startAdding()
            } label: {
                Iconsax(.add, size: 24)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Add Product")
            .disabled(viewModel.data == nil)
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if let data = viewModel.data {
            statsRow(data)
            if data.products.isEmpty {
                EmptyState(
                    icon: .box,
                    title: "No products yet",
                    message: "Add your first product to show it on your website.",
                    actionTitle: "Add Product",
                    actionIcon: .add,
                    dashed: true,
                    action: viewModel.startAdding
                )
            } else {
                SearchField(text: $viewModel.searchQuery)
                categoryChips
                productsGrid
            }
        } else if case .failed(let message) = viewModel.phase {
            ErrorState(message: message) {
                Task { await viewModel.retryLoad() }
            }
        } else {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(0..<6, id: \.self) { _ in SkeletonCard() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading products")
        }
    }

    private func statsRow(_ data: WebsiteProductsData) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(icon: .box, iconForeground: Theme.brandStrong, iconBackground: Theme.brandSoft,
                         label: "Total catalog", value: "\(data.products.count)")
                StatCard(icon: .star1, iconForeground: Theme.warning, iconBackground: Theme.warningSoft,
                         label: "Featured", value: "\(viewModel.featuredCount)")
                StatCard(icon: .category, iconForeground: Theme.brandStrong, iconBackground: Theme.brandSoft,
                         label: "Categories", value: "\(data.categories.count)")
                StatCard(icon: .tickCircle,
                         iconForeground: data.isLive ? Theme.success : Theme.mutedForeground,
                         iconBackground: data.isLive ? Theme.successSoft : Theme.muted,
                         label: "Live status", value: data.isLive ? "Live" : "Offline")
            }
            // Room for the card shadow, which a scroll view would otherwise clip.
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, -16)
        .padding(.vertical, -8)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(viewModel.categories, id: \.self) { category in
                    Chip(title: category, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
        .padding(.vertical, -6)
    }

    @ViewBuilder
    private var productsGrid: some View {
        let products = viewModel.filteredProducts
        if products.isEmpty {
            EmptyState(icon: .searchNormal1, title: "No products found", message: noResultsMessage)
        } else {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(products) { product in
                    ProductCard(
                        product: product,
                        currency: viewModel.currency,
                        onEdit: { viewModel.startEditing(product) },
                        onToggleFeatured: { Task { await viewModel.toggleFeatured(product) } },
                        onDelete: { viewModel.requestDelete(product) }
                    )
                }
            }
            .animation(.easeOut(duration: 0.2), value: products)
        }
    }

    private var noResultsMessage: String {
        let query = viewModel.trimmedQuery
        if query.isEmpty, let category = viewModel.selectedCategory {
            return "There are no products in \"\(category)\" yet. Try another search or category."
        }
        return "No products matched \"\(query)\". Try another search or category."
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 210, maximum: 320), spacing: gridSpacing, alignment: .top)]
        }
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing, alignment: .top), count: 2)
    }

    private var gridSpacing: CGFloat { horizontalSizeClass == .regular ? 16 : 12 }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDelete != nil },
            set: { if !$0 { viewModel.pendingDelete = nil } }
        )
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ sheet: ProductsViewModel.Sheet) -> some View {
        switch sheet {
        case .add, .edit:
            let editing: ManagedProduct? = if case .edit(let product) = sheet { product } else { nil }
            ProductFormSheet(
                product: editing,
                currency: viewModel.currency,
                categories: viewModel.categories,
                suggestedCategory: viewModel.selectedCategory,
                onUpload: { try await viewModel.uploadImage($0) },
                onSave: { try await viewModel.save($0, editing: editing) },
                onCancel: { viewModel.activeSheet = nil }
            )
        case .publish:
            PublishStatusSheet(
                status: viewModel.deployStatus,
                errorMessage: viewModel.deployError,
                isStarting: viewModel.isTriggeringDeploy,
                onRetry: { Task { await viewModel.retryPublish() } },
                onViewSite: { openURL(viewModel.website.liveURL) },
                onClose: { viewModel.activeSheet = nil }
            )
            .task(id: viewModel.deployPollToken) {
                await viewModel.pollDeployStatus()
            }
        }
    }
}

#Preview("Filled") {
    ProductsView(viewModel: .preview())
}

#Preview("Loading") {
    ProductsView(viewModel: .preview(.init(latency: .seconds(3600))))
}

#Preview("Empty") {
    ProductsView(viewModel: .preview(.init(startsEmpty: true)))
}

#Preview("Error") {
    ProductsView(viewModel: .preview(.init(failsLoading: true)))
}

#Preview("iPad", traits: .landscapeLeft) {
    ProductsView(viewModel: .preview())
}
