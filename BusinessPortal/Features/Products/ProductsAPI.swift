import Foundation

/// The only swap point between the app and the backend. Replace `MockProductsAPI` with an
/// HTTP implementation once the Spring Boot API is ready; nothing else needs to change.
protocol ProductsAPI: Sendable {
    func getProducts(websiteId: String) async throws -> WebsiteProductsData
    func addProduct(websiteId: String, input: AddProductInput) async throws -> ManagedProduct
    func updateProduct(websiteId: String, id: String, input: AddProductInput) async throws -> ManagedProduct
    func deleteProduct(websiteId: String, id: String) async throws
    /// Uploads image bytes and returns the URL to store in `imageUrl`.
    func uploadImage(websiteId: String, data: Data) async throws -> String
    /// Starts a new deploy of the website and returns its first status.
    func triggerDeploy(websiteId: String) async throws -> DeployStatus
    /// Status of the website's most recent deploy (including ones started by `autoDeploy`).
    func getDeployStatus(websiteId: String) async throws -> DeployStatus
}

// MARK: - Mock

/// In-memory stand-in for the backend: async, ~400ms latency, throws `APIError`.
/// The deploy pipeline is the backend's; the mock only reports a stage based on time since
/// the deploy started, the way the real API would.
actor MockProductsAPI: ProductsAPI {
    struct Options: Sendable {
        var latency: Duration = .milliseconds(400)
        var startsEmpty = false
        var failsLoading = false
        var failsFirstDeploy = false
    }

    private struct Deploy {
        let id: String
        let startedAt: Date
        let fails: Bool
    }

    static let maxImageBytes = 5 * 1024 * 1024

    private let options: Options
    private var data: WebsiteProductsData
    private var deploy: Deploy
    private var shouldFailNextDeploy: Bool

    init(options: Options = Options()) {
        self.options = options
        self.data = options.startsEmpty ? Self.emptySeed : Self.cafeSeed
        self.deploy = Deploy(id: UUID().uuidString, startedAt: .now.addingTimeInterval(-7200), fails: false)
        self.shouldFailNextDeploy = options.failsFirstDeploy
    }

    func getProducts(websiteId: String) async throws -> WebsiteProductsData {
        try await respond()
        if options.failsLoading {
            throw APIError(message: "We couldn't reach your website's catalog. Check your connection and try again.")
        }
        return data
    }

    func addProduct(websiteId: String, input: AddProductInput) async throws -> ManagedProduct {
        try await respond()
        try validate(input, excluding: nil)
        let product = ManagedProduct(
            id: UUID().uuidString.lowercased(),
            name: input.name,
            description: input.description,
            price: input.price,
            category: input.category,
            imageUrl: input.imageUrl,
            featured: input.featured
        )
        data.products.insert(product, at: 0)
        addCategoryIfNeeded(input.category)
        if input.autoDeploy { startDeploy() }
        return product
    }

    func updateProduct(websiteId: String, id: String, input: AddProductInput) async throws -> ManagedProduct {
        try await respond()
        guard let index = data.products.firstIndex(where: { $0.id == id }) else {
            throw APIError(message: "This product no longer exists. Pull to refresh your catalog.")
        }
        try validate(input, excluding: id)
        var product = data.products[index]
        product.name = input.name
        product.description = input.description
        product.price = input.price
        product.category = input.category
        product.imageUrl = input.imageUrl
        product.featured = input.featured
        data.products[index] = product
        addCategoryIfNeeded(input.category)
        if input.autoDeploy { startDeploy() }
        return product
    }

    func deleteProduct(websiteId: String, id: String) async throws {
        try await respond()
        guard data.products.contains(where: { $0.id == id }) else {
            throw APIError(message: "This product no longer exists. Pull to refresh your catalog.")
        }
        data.products.removeAll { $0.id == id }
        startDeploy()
    }

    func uploadImage(websiteId: String, data imageData: Data) async throws -> String {
        try await respond()
        guard imageData.count <= Self.maxImageBytes else {
            throw APIError(message: "Images must be 5 MB or smaller.")
        }
        let folder = URL.cachesDirectory.appending(path: "mock-uploads", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "\(UUID().uuidString.lowercased()).img")
        do {
            try imageData.write(to: file)
        } catch {
            throw APIError(message: "The image couldn't be uploaded. Try again.")
        }
        return file.absoluteString
    }

    func triggerDeploy(websiteId: String) async throws -> DeployStatus {
        try await respond()
        startDeploy()
        return status()
    }

    func getDeployStatus(websiteId: String) async throws -> DeployStatus {
        try await respond()
        return status()
    }

    // MARK: Helpers

    private func respond() async throws {
        try await Task.sleep(for: options.latency)
    }

    private func validate(_ input: AddProductInput, excluding id: String?) throws {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw APIError(message: "Product name is required.") }
        let duplicate = data.products.contains {
            $0.id != id && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
        if duplicate {
            throw APIError(message: "A product named \"\(name)\" already exists in your catalog.")
        }
        guard let price = Decimal(string: input.price, locale: Currency.posix), price > 0 else {
            throw APIError(message: "Price must be greater than 0.")
        }
    }

    private func addCategoryIfNeeded(_ category: String) {
        if !data.categories.contains(where: { $0.localizedCaseInsensitiveCompare(category) == .orderedSame }) {
            data.categories.append(category)
        }
    }

    private func startDeploy() {
        deploy = Deploy(id: UUID().uuidString.lowercased(), startedAt: .now, fails: shouldFailNextDeploy)
        shouldFailNextDeploy = false
    }

    private func status() -> DeployStatus {
        let now = Date.now
        let elapsed = now.timeIntervalSince(deploy.startedAt)
        if deploy.fails && elapsed >= 3 {
            return DeployStatus(
                deployId: deploy.id,
                stage: .building,
                failed: true,
                message: "The build stopped because an image couldn't be processed. Your current website is still online.",
                updatedAt: now
            )
        }
        let stage: DeployStage = switch elapsed {
        case ..<1.5: .queued
        case ..<4: .building
        case ..<6: .publishing
        default: .live
        }
        return DeployStatus(deployId: deploy.id, stage: stage, failed: false, message: nil, updatedAt: now)
    }

    // MARK: Seed data

    private static let emptySeed = WebsiteProductsData(
        websiteId: PortalWebsite.demo.id,
        siteName: "Riverside Bakehouse",
        currency: .usd,
        isLive: true,
        categories: [],
        products: []
    )

    private static let cafeSeed = WebsiteProductsData(
        websiteId: PortalWebsite.demo.id,
        siteName: "Riverside Bakehouse",
        currency: .usd,
        isLive: true,
        categories: ["Coffee", "Cold drinks", "Pastries", "Cakes"],
        products: [
            ManagedProduct(
                id: "3f6c1d2a-8b4e-4c71-9a0e-1b2c3d4e5f60",
                name: "Flat white",
                description: "Double ristretto with silky steamed milk, made with our house blend.",
                price: "3.50",
                category: "Coffee",
                imageUrl: "/mock/templates/warm-bold/flat-white.webp",
                featured: true
            ),
            ManagedProduct(
                id: "8a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d",
                name: "Iced cold brew",
                description: "Steeped for 18 hours for a smooth, chocolatey finish.",
                price: "3.75",
                category: "Cold drinks",
                imageUrl: "/mock/templates/warm-bold/cold-brew.webp",
                featured: false
            ),
            ManagedProduct(
                id: "c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f",
                name: "Iced palm sugar latte",
                description: "Espresso, fresh milk and Kampong Speu palm sugar over ice.",
                price: "3.25",
                category: "Cold drinks",
                imageUrl: nil,
                featured: true
            ),
            ManagedProduct(
                id: "d4e5f6a7-b8c9-4d0e-8f1a-2b3c4d5e6f70",
                name: "Double espresso",
                description: "Two shots pulled short. Bright, sweet and bold.",
                price: "2.50",
                category: "Coffee",
                imageUrl: "/mock/templates/warm-bold/hero-espresso.webp",
                featured: false
            ),
            ManagedProduct(
                id: "e5f6a7b8-c9d0-4e1f-9a2b-3c4d5e6f7081",
                name: "Cinnamon bun",
                description: "Baked every morning with brown butter and a cream cheese glaze.",
                price: "2.75",
                category: "Pastries",
                imageUrl: "/mock/templates/warm-bold/cinnamon-bun.webp",
                featured: true
            ),
            ManagedProduct(
                id: "f6a7b8c9-d0e1-4f2a-8b3c-4d5e6f708192",
                name: "Lemon tart",
                description: "Buttery shortcrust filled with tangy lemon curd.",
                price: "3.00",
                category: "Pastries",
                imageUrl: "/mock/templates/sweet-pastel/lemon-tart.webp",
                featured: false
            ),
            ManagedProduct(
                id: "a7b8c9d0-e1f2-4a3b-9c4d-5e6f708192a3",
                name: "Chocolate fudge cake",
                description: "Rich dark chocolate layers. Sold by the slice.",
                price: "4.50",
                category: "Cakes",
                imageUrl: "/mock/templates/sweet-pastel/chocolate-fudge-cake.webp",
                featured: false
            ),
            ManagedProduct(
                id: "b8c9d0e1-f2a3-4b4c-8d5e-6f708192a3b4",
                name: "Strawberry cupcake",
                description: "Vanilla sponge topped with fresh strawberry buttercream.",
                price: "2.25",
                category: "Cakes",
                imageUrl: "/mock/templates/sweet-pastel/strawberry-cupcake.webp",
                featured: false
            ),
        ]
    )
}
