import SwiftUI

enum PortalTab: Hashable {
    case products, businessInfo, monitoring
}

/// Business Portal shell: Products, Business info and Monitoring, in the web app's order.
/// A tab bar on iPhone; on iPad (iOS 18+) the tabs can turn into a sidebar.
struct PortalRootView: View {
    @State private var products: ProductsViewModel
    @State private var selection: PortalTab = .products

    init(api: any ProductsAPI = MockProductsAPI(), website: PortalWebsite = .demo) {
        _products = State(initialValue: ProductsViewModel(api: api, website: website))
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $selection) {
                    Tab("Products", image: PortalIcon.box.rawValue, value: PortalTab.products) {
                        productsTab
                    }
                    Tab("Business info", image: PortalIcon.shop.rawValue, value: PortalTab.businessInfo) {
                        businessInfoTab
                    }
                    Tab("Monitoring", image: PortalIcon.activity.rawValue, value: PortalTab.monitoring) {
                        monitoringTab
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
            } else {
                TabView(selection: $selection) {
                    productsTab
                        .tabItem { Label { Text("Products") } icon: { PortalIcon.box.image } }
                        .tag(PortalTab.products)
                    businessInfoTab
                        .tabItem { Label { Text("Business info") } icon: { PortalIcon.shop.image } }
                        .tag(PortalTab.businessInfo)
                    monitoringTab
                        .tabItem { Label { Text("Monitoring") } icon: { PortalIcon.activity.image } }
                        .tag(PortalTab.monitoring)
                }
            }
        }
        .tint(Theme.primary)
    }

    private var productsTab: some View {
        ProductsView(viewModel: products)
    }

    private var businessInfoTab: some View {
        PlaceholderSectionView(
            title: "Business info",
            subtitle: "Your business details, hours and contact information.",
            icon: .shop,
            emptyTitle: "Coming soon to iOS",
            emptyMessage: "You can edit your business info in the web portal for now.",
            siteName: products.data?.siteName,
            isLive: products.data?.isLive ?? false
        )
    }

    private var monitoringTab: some View {
        PlaceholderSectionView(
            title: "Monitoring",
            subtitle: "Visits, uptime and publish history for your website.",
            icon: .activity,
            emptyTitle: "No monitoring data yet",
            emptyMessage: "Website visits and uptime will show here once they're available.",
            siteName: products.data?.siteName,
            isLive: products.data?.isLive ?? false
        )
    }
}

/// Owner section that isn't built yet: title plus an empty state.
struct PlaceholderSectionView: View {
    let title: String
    let subtitle: String
    let icon: PortalIcon
    let emptyTitle: String
    let emptyMessage: String
    let siteName: String?
    let isLive: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(Typography.screenTitle)
                            .foregroundStyle(Theme.primary)
                            .accessibilityAddTraits(.isHeader)
                        Text(subtitle)
                            .font(Typography.secondary)
                            .foregroundStyle(Theme.mutedForeground)
                    }
                    EmptyState(icon: icon, title: emptyTitle, message: emptyMessage, dashed: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PortalHeader(siteName: siteName, isLive: isLive)
                }
            }
        }
    }
}

#Preview("Portal") {
    PortalRootView()
}

#Preview("Business info") {
    PlaceholderSectionView(
        title: "Business info",
        subtitle: "Your business details, hours and contact information.",
        icon: .shop,
        emptyTitle: "Coming soon to iOS",
        emptyMessage: "You can edit your business info in the web portal for now.",
        siteName: "Riverside Bakehouse",
        isLive: true
    )
}
