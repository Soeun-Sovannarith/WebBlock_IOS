import Foundation

/// A product in the website's catalog. Matches the API payload exactly.
struct ManagedProduct: Codable, Identifiable, Hashable, Sendable {
    let id: String          // UUID
    var name: String
    var description: String
    var price: String       // decimal string, e.g. "4.50"
    var category: String
    var imageUrl: String?
    var featured: Bool
}
