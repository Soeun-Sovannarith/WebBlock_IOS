import Foundation

struct WebsiteProductsData: Codable, Hashable, Sendable {
    let websiteId: String
    let siteName: String
    let currency: Currency
    let isLive: Bool
    var categories: [String]
    var products: [ManagedProduct]
}

enum Currency: String, Codable, Hashable, Sendable {
    case usd = "USD"
    case khr = "KHR"

    var symbol: String {
        switch self {
        case .usd: "$"
        case .khr: "៛"
        }
    }

    var fractionDigits: Int {
        switch self {
        case .usd: 2
        case .khr: 0
        }
    }

    var pricePlaceholder: String {
        switch self {
        case .usd: "4.50"
        case .khr: "18000"
        }
    }

    /// Display price: USD → "$4.50", KHR → "18,000៛".
    func format(_ price: String) -> String {
        guard let value = Decimal(string: price, locale: Self.posix) else { return price }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        let number = formatter.string(from: value as NSDecimalNumber) ?? price
        switch self {
        case .usd: return "$\(number)"
        case .khr: return "\(number)៛"
        }
    }

    /// API price string: "4.5" → "4.50" for USD, "18000.0" → "18000" for KHR.
    func normalize(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Self.posix
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }

    static let posix = Locale(identifier: "en_US_POSIX")
}
