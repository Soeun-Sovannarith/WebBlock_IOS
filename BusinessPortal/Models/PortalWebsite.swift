import Foundation

/// The website the signed-in owner is managing.
struct PortalWebsite: Hashable, Sendable {
    let id: String
    let liveURL: URL

    static let demo = PortalWebsite(
        id: "7c0e2a8e-5d4b-4e43-9a61-3f1f2b6c8d10",
        liveURL: URL(string: "https://riverside-bakehouse.webblock.app")!
    )
}
