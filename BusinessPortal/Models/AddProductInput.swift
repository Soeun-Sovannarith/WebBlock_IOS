import Foundation

/// Body for create and update requests.
struct AddProductInput: Codable, Hashable, Sendable {
    var name: String
    var description: String
    var price: String
    var category: String
    var imageUrl: String?
    var featured: Bool
    var autoDeploy: Bool
}

extension AddProductInput {
    init(product: ManagedProduct, autoDeploy: Bool) {
        self.init(
            name: product.name,
            description: product.description,
            price: product.price,
            category: product.category,
            imageUrl: product.imageUrl,
            featured: product.featured,
            autoDeploy: autoDeploy
        )
    }
}
