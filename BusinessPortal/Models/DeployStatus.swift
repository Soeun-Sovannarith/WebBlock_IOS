import Foundation

/// The latest deploy of a website, as reported by the backend.
struct DeployStatus: Codable, Hashable, Sendable {
    let deployId: String    // UUID
    let stage: DeployStage
    let failed: Bool
    let message: String?    // set when `failed` is true
    let updatedAt: Date     // ISO-8601 UTC

    var isFinished: Bool { failed || stage == .live }
}

enum DeployStage: String, Codable, CaseIterable, Hashable, Sendable {
    case queued = "QUEUED"
    case building = "BUILDING"
    case publishing = "PUBLISHING"
    case live = "LIVE"

    var title: String {
        switch self {
        case .queued: "Queued"
        case .building: "Building"
        case .publishing: "Publishing"
        case .live: "Live"
        }
    }

    var detail: String {
        switch self {
        case .queued: "Waiting for a build slot"
        case .building: "Preparing your pages and images"
        case .publishing: "Sending your website to the web"
        case .live: "Visitors see the latest version"
        }
    }
}
