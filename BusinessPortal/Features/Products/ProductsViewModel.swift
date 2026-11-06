import Foundation
import Observation

/// Holds the Products screen state and is the only caller of `ProductsAPI`.
@MainActor
@Observable
final class ProductsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    enum Sheet: Identifiable, Hashable {
        case add
        case edit(ManagedProduct)
        case publish

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let product): "edit-\(product.id)"
            case .publish: "publish"
            }
        }
    }

    let website: PortalWebsite
    private let api: any ProductsAPI

    private(set) var phase: Phase = .loading
    private(set) var data: WebsiteProductsData?

    var searchQuery = ""
    /// `nil` means "All".
    var selectedCategory: String?
    var activeSheet: Sheet?
    var pendingDelete: ManagedProduct?
    var toast: Toast?

    // Publish status, exactly as returned by the API.
    private(set) var deployStatus: DeployStatus?
    private(set) var deployError: String?
    private(set) var isTriggeringDeploy = false
    /// Changing this restarts polling in `PublishStatusSheet`.
    private(set) var deployPollToken = 0

    // Haptic triggers observed by the view.
    private(set) var successFeedback = 0
    private(set) var warningFeedback = 0

    init(api: any ProductsAPI, website: PortalWebsite) {
        self.api = api
        self.website = website
    }

    // MARK: Derived state

    var products: [ManagedProduct] { data?.products ?? [] }
    var categories: [String] { data?.categories ?? [] }
    var currency: Currency { data?.currency ?? .usd }
    var featuredCount: Int { products.filter(\.featured).count }

    var trimmedQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var filteredProducts: [ManagedProduct] {
        let query = trimmedQuery
        return products.filter { product in
            let matchesCategory = selectedCategory.map {
                product.category.localizedCaseInsensitiveCompare($0) == .orderedSame
            } ?? true
            let matchesQuery = query.isEmpty
                || product.name.localizedCaseInsensitiveContains(query)
                || product.description.localizedCaseInsensitiveContains(query)
                || product.category.localizedCaseInsensitiveContains(query)
            return matchesCategory && matchesQuery
        }
    }

    // MARK: Loading

    func loadIfNeeded() async {
        guard data == nil else { return }
        await load()
    }

    func load() async {
        if data == nil { phase = .loading }
        do {
            data = try await api.getProducts(websiteId: website.id)
            phase = .loaded
        } catch is CancellationError {
            return
        } catch {
            if data == nil {
                phase = .failed(error.portalMessage)
            } else {
                toast = .error("Couldn't refresh products", error.portalMessage)
            }
        }
    }

    func retryLoad() async {
        phase = .loading
        await load()
    }

    // MARK: Products

    func startAdding() {
        activeSheet = .add
    }

    func startEditing(_ product: ManagedProduct) {
        activeSheet = .edit(product)
    }

    /// Saves the form. Throws so the form can show the API message in its error banner.
    func save(_ input: AddProductInput, editing product: ManagedProduct?) async throws {
        let saved: ManagedProduct
        if let product {
            saved = try await api.updateProduct(websiteId: website.id, id: product.id, input: input)
            replace(saved)
            toast = .success("Product updated", "\(saved.name) has been updated.")
        } else {
            saved = try await api.addProduct(websiteId: website.id, input: input)
            data?.products.insert(saved, at: 0)
            toast = .success("Product added", "\(saved.name) has been added to the catalog.")
        }
        addCategoryIfNeeded(saved.category)
        successFeedback += 1

        if input.autoDeploy {
            showPublishStatus()
        } else {
            activeSheet = nil
        }
    }

    func uploadImage(_ imageData: Data) async throws -> String {
        try await api.uploadImage(websiteId: website.id, data: imageData)
    }

    func toggleFeatured(_ product: ManagedProduct) async {
        var input = AddProductInput(product: product, autoDeploy: true)
        input.featured.toggle()
        do {
            let saved = try await api.updateProduct(websiteId: website.id, id: product.id, input: input)
            replace(saved)
            toast = .success(
                "Product updated",
                saved.featured ? "\(saved.name) is now featured on your homepage." : "\(saved.name) is no longer featured."
            )
            successFeedback += 1
        } catch {
            toast = .error("Couldn't update product", error.portalMessage)
        }
    }

    func requestDelete(_ product: ManagedProduct) {
        pendingDelete = product
        warningFeedback += 1
    }

    func confirmDelete(_ product: ManagedProduct) async {
        pendingDelete = nil
        do {
            try await api.deleteProduct(websiteId: website.id, id: product.id)
            data?.products.removeAll { $0.id == product.id }
            toast = .success("Product removed", "\(product.name) was removed from the catalog.")
        } catch {
            toast = .error("Couldn't remove product", error.portalMessage)
        }
    }

    // MARK: Publishing

    /// "Publish changes": asks the backend to deploy, then shows its status.
    func publishChanges() async {
        deployStatus = nil
        deployError = nil
        activeSheet = .publish
        isTriggeringDeploy = true
        defer { isTriggeringDeploy = false }
        do {
            deployStatus = try await api.triggerDeploy(websiteId: website.id)
            deployPollToken += 1
        } catch {
            deployError = error.portalMessage
        }
    }

    /// "Try again" in the publish sheet: redeploy after a failed deploy, otherwise re-read status.
    func retryPublish() async {
        if deployStatus?.failed == true || deployStatus == nil {
            await publishChanges()
        } else {
            deployError = nil
            deployPollToken += 1
        }
    }

    /// Polls the latest deploy until it is live or failed. Runs for as long as the publish
    /// sheet is on screen (the sheet's `.task` cancels it on dismiss).
    func pollDeployStatus() async {
        guard !isTriggeringDeploy else { return }
        while !Task.isCancelled {
            do {
                let status = try await api.getDeployStatus(websiteId: website.id)
                deployStatus = status
                deployError = nil
                if status.isFinished { return }
            } catch is CancellationError {
                return
            } catch {
                deployError = error.portalMessage
                return
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func showPublishStatus() {
        deployStatus = nil
        deployError = nil
        deployPollToken += 1
        activeSheet = .publish
    }

    // MARK: Helpers

    private func replace(_ product: ManagedProduct) {
        guard let index = data?.products.firstIndex(where: { $0.id == product.id }) else { return }
        data?.products[index] = product
    }

    private func addCategoryIfNeeded(_ category: String) {
        guard let data, !data.categories.contains(where: {
            $0.localizedCaseInsensitiveCompare(category) == .orderedSame
        }) else { return }
        self.data?.categories.append(category)
    }
}

// MARK: - Previews

extension ProductsViewModel {
    static func preview(_ options: MockProductsAPI.Options = .init()) -> ProductsViewModel {
        ProductsViewModel(api: MockProductsAPI(options: options), website: .demo)
    }
}
