import SwiftUI

/// Iconsax (Linear) icons exported as template SVGs in `Assets.xcassets`.
enum PortalIcon: String, CaseIterable {
    case activity = "IconActivity"
    case add = "IconAdd"
    case box = "IconBox"
    case camera = "IconCamera"
    case category = "IconCategory"
    case clock = "IconClock"
    case closeCircle = "IconCloseCircle"
    case closeSquare = "IconCloseSquare"
    case cpu = "IconCpu"
    case danger = "IconDanger"
    case edit2 = "IconEdit2"
    case export = "IconExport"
    case exportSquare = "IconExportSquare"
    case flash = "IconFlash"
    case gallery = "IconGallery"
    case global = "IconGlobal"
    case more = "IconMore"
    case refresh2 = "IconRefresh2"
    case searchNormal1 = "IconSearchNormal1"
    case shop = "IconShop"
    case star1 = "IconStar1"
    case star1Filled = "IconStar1Bold"
    case tickCircle = "IconTickCircle"
    case trash = "IconTrash"

    var image: Image {
        Image(rawValue).renderingMode(.template)
    }
}

/// A decorative Iconsax icon at a fixed size, tinted by the current foreground style.
struct Iconsax: View {
    let icon: PortalIcon
    var size: CGFloat = 20

    nonisolated init(_ icon: PortalIcon, size: CGFloat = 20) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        icon.image
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
