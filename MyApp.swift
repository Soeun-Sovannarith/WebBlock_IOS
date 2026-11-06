import SwiftUI

@main
struct MyApp: App {
    init() {
        PortalFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            PortalRootView(api: MockProductsAPI(), website: .demo)
                // The web app has no dark mode yet.
                .preferredColorScheme(.light)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }
}
