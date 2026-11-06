Here's the prompt. It assumes a native SwiftUI app. I took every value from the current web app: the colors, shadows and button shapes from
src/app/globals.css, and the layout, fields and wording from tc/features/portal/components/products-manager.tsx andproduct-dialog.tsx).

# Build: WebBlock Business Portal (iOS) — Products screen

## Context
WebBlock lets small businesses in Cambodia build a website froowner
uses the "Business Portal" to manage the products shown on their website. Build the iOS version
of this portal in **SwiftUI (iOS 17+)**. It must look like thepp:
same colors, fonts, shapes, wording and states. The backend (Spring Boot) is not ready, so
use mock data behind a single `ProductsAPI` protocol that can I later.

## Hard rules
1. **No transactions.** No cart, checkout, payment, booking or WhatsApp anywhere. Products are
   a catalog to display, not something to sell in the app.
2. **The backend owns the logic.** The app only triggers and displays: deploying, retries and
   deploy status come from the API. Don't simulate a real pipestatus
   the API returns.
3. **Never hardcode colors.** Put every color in one `Theme` fr a
   `Color` extension) using the token names below, and use only those in views.
4. Data shape matches the API exactly: camelCase, UUID string string**
   ("4.50"), ISO-8601 UTC dates.

## Design tokens (copy exactly)
Colors:
| Token | Hex | Use |
|---|---|---|
| background | #FFFFFF | screens, cards |
| foreground | #1B2B4B | main text |
| foregroundSoft | #33486F | ghost buttons, secondary actions |
| mutedForeground | #5A6B8C | secondary text |
| placeholder | #7C8DAE | placeholder text, empty icons |
| hint | #8A9AB8 | helper text under fields |
| muted | #F6F9FE | subtle fills, image wells |
| surface | #F9FAFB | grouped background |
| border | #E5E7EB | card and input borders |
| borderStrong | #7C8DAE | outline buttons |
| primary | #4379D6 | page titles, links, focus ring, selected chip |
| primarySoft | #EEF4FD | selected chip background |
| brand | #2F6BC4 | primary button fill |
| brandStrong | #2A5FBD | text/icon on brandSoft |
| brandSoft | #E3EEFC | icon tiles |
| brandDeep | #1F4FB5 | selected item text |
| brandBorder | #9DBBE9 | selected item border |
| heading | #1F3C6E | big headings, logo wordmark |
| segment | #EEF2F8 | segmented control track |
| dropzone | #F5F8FE (border #9DBDEB, dashed) | image upload a
| fieldLocked | #F4F7FC | read-only fields |
| success / successSoft | #1E8A5A / #E6F5EC | "Live", synced |
| warning / warningSoft | #D97706 / #FDF1E0 | "Featured" badge, warnings |
| danger / dangerSoft | #CC3D3D / #FCE8E8 | delete, errors |
| scrim | #0B1530 @ 34% | behind sheets/dialogs |

Light mode only for now (the web app has no dark mode). Lock the app to light appearance.

Shadows (all blue-tinted, never black):
- card: x5 y6 blur12, #3C78CF @ 5%
- button: y1 blur1, #3C78CF @ 6%
- buttonPressed/hover: y4 blur10, #2F6BC4 @ 18%
- float (sheets, menus): y10 blur30, #3C78CF @ 12%
- dialog: y24 blur60, #0F172A @ 20%

Typography (bundle both from Google Fonts as .ttf, support Dyn:
- Headings: **Familjen Grotesk** (Bold/SemiBold). Screen title 24pt bold, section 18pt semibold,
  card title 15pt semibold.
- Body: **DM Sans**. Body 15pt, secondary 13pt, labels 12pt semibold, captions 11pt medium.
- Page titles are colored `primary` (#4379D6).

Shapes:
- Buttons are **fully rounded capsules**. Height 40pt (regular) / 32pt (small), 18pt horizontal
  padding, semibold text. Primary = brand fill + white text +
  Secondary = white fill + border. Ghost = no fill, foregroundSoft text. Destructive = danger.
- Cards: corner radius 16, 1pt border, card shadow, 14pt paddi
- Image wells and thumbnails: radius 12. Sheets/dialogs: radius 24.
- Inputs: radius 12, 1pt border, 44pt min height, focus = 2pt
- Chips (filters, categories): capsule, 12pt medium text. Selected = primary fill, white text.
  Unselected = muted fill, mutedForeground text.
- **Product images are always 4:3**, aspect-fill, cropped.

Icons: **Iconsax** (Linear style, same set as the web app) exported as SVG into the asset
catalog, template-rendered so they take the token color. Iconsit2,
Trash, SearchNormal1, Gallery, Export, ExportSquare, Flash, TickCircle, Cpu.
Icon tiles = 40×40, radius 12, brandSoft background, brandStro

Motion: short and calm. Sheets use the standard iOS spring, lis,
toasts slide down from the top over 200ms. Respect Reduce Motion.

## Data model
```swift
struct ManagedProduct: Codable, Identifiable, Hashable {
  let id: String          // UUID
  var name: String
  var description: String
  var price: String       // decimal string, e.g. "4.50"
  var category: String
  var imageUrl: String?
  var featured: Bool
}

struct WebsiteProductsData: Codable {
  let websiteId: String
  let siteName: String
  let currency: Currency  // "USD" | "KHR"
  let isLive: Bool
  var categories: [String]
  var products: [ManagedProduct]
}

struct AddProductInput: Codable {
  var name: String
  var description: String
  var price: String
  var category: String
  var imageUrl: String?
  var featured: Bool
  var autoDeploy: Bool
}
```
`ProductsAPI` protocol: `getProducts(websiteId)`, `addProduct(
`updateProduct(websiteId, id, input)`, `deleteProduct(websiteId, id)`,
`uploadImage(websiteId, data) -> url`, `triggerDeploy(websiteI
Mock version: async, ~400ms delay, throws `APIError(message:)` on failure. Seed it with
8 products across 3–4 categories (a small café/bakery: drinks,atured.

Price formatting: USD → "$4.50"; KHR → "18,000៛" (no decimals,

## Navigation
Tab bar (or sidebar on iPad) with the three owner sections, same order as the web:
**Products**, **Business info**, **Monitoring**. Build **Produ are
placeholder screens with the title and an empty state.
Top of the portal: website name + a status pill ("Live" in suc

## Screen 1 — Products (list)
- Large title "Products" in primary. Subtitle in mutedForeground:
  "Manage your storefront. Changes are published to your live
- Toolbar: `+` (Add Product, primary), overflow menu with "View live site" (opens the website
  URL in Safari) and "Publish changes" (calls triggerDeploy).
- **Stats row** (horizontal scroll, cards with icon tile + label + value):
  Total catalog (Box) · Featured (Star1, warning colors) · Cat
  Live status (TickCircle, success colors).
- **Search** field (SearchNormal1 icon, "Search products…"), fn, category.
- **Category chips**, horizontal scroll: "All" + each category.
- **Grid**: 2 columns on iPhone, 3–4 on iPad. Product card:
  - 4:3 image (muted well with a Box icon when there's no image)
  - "Featured" badge top-left (warning fill, white text, Star1
  - Price pill bottom-right (white, bold, small shadow)
  - Category in 11pt brand color, name 15pt semibold (1 line), lines)
  - Footer divider, then "Live" (success, TickCircle) on the left and Edit / Delete icon
    buttons on the right
- Tap card → Edit sheet. Long-press → context menu (Edit, Feature/Unfeature, Delete).
  Swipe to delete is fine in a list layout.
- Pull to refresh.

States (all required):
- Loading: skeleton cards (muted shimmer), same grid size.
- Empty catalog: dashed-border card, Box icon tile, "No products yet",
  "Add your first product to show it on your website.", primar
- No search results: "No products found", "No products matched "<query>". Try another search
  or category."
- Error: danger icon, the API message, "Try again" button.

## Screen 2 — Add / Edit Product (sheet, .large detent)
Header: icon tile (Add or Edit2) + title "Add New Product" / "n.
Fields, top to bottom (labels 12pt semibold foreground, required marked):
1. **Image**: dashed dropzone (dropzone colors) showing a 4:3 photo"
   (PhotosPicker), "Take photo" (camera), "Remove". Rules: PNG, JPG or WebP, max 5 MB. Show
   the rule as hint text and a danger message if violated. Uplwith
   a progress state.
2. **Product name*** — placeholder "e.g. Matcha Basque Cheesec
3. **Price*** — decimal keypad, currency symbol prefix from site currency, placeholder "4.50".
   Must be > 0, max 2 decimals (0 decimals for KHR). Send as a
4. **Category*** — chips of existing categories (selected = primarySoft fill, brandBorder
   border, brandDeep text) plus a text field "Or type a new ca
5. **Short description** — multi-line, max 160 chars with a live counter,
   placeholder "Freshly baked in small batches with premium in
6. **Toggles** card (muted fill): "Feature on homepage" (Star1) and
   "Publish to website now" (Flash, on by default) → `autoDepl
Inline validation under each field in danger color. A top error banner (dangerSoft) for API errors.
Sticky footer: Cancel (ghost) + Save (primary capsule, shows a
disabled until valid). Warn before dismissing the sheet if there are unsaved changes.

After save: success toast ("Product added" / "Product updated", "<name> has been added
to the catalog."), and if autoDeploy, open Screen 3.

## Screen 3 — Publish status (sheet, .medium detent)
Shows the deploy status **returned by the API** as a vertical step list:
Queued → Building → Publishing → Live. Current step = primary
TickCircle, failed = danger with the API message and a "Try again" button. Ends with
"Your website is updated" + "View live site". Poll the API sta

## Delete confirmation
Native alert / confirmation dialog: title `Delete "<name>"?`, message "This removes the product
from your catalog and updates your live website.", destructive
Then a toast "Product removed".

## Toasts
Top-of-screen banner, white card with float shadow, radius 16.
TickCircle / danger. Title 14pt semibold + one line of muted text. Auto-dismiss after 4 seconds.

## Accessibility & quality
- Minimum 44×44 tap targets, VoiceOver labels on every icon bu
  "Delete <name>"), Dynamic Type up to XXL without clipping, contrast ≥ 4.5:1.
- Haptics: success on save, warning on delete.
- iPhone SE through Pro Max, and iPad (grid adapts).

## Structure
```
BusinessPortal/
  Theme/           Colors.swift, Typography.swift, Shadows.swi
  Components/      PrimaryButton, Chip, Card, IconTile, StatusPill, Toast, EmptyState, ErrorState, SkeletonCard
  Features/Products/
    ProductsAPI.swift        protocol + MockProductsAPI (the only swap point)
    ProductsViewModel.swift  @Observable, holds state, calls t
    ProductsView.swift, ProductCard.swift, ProductFormSheet.swift, PublishStatusSheet.swift
  Models/          ManagedProduct, WebsiteProductsData, AddProror
```
Views never call the mock directly; they go through the view m
Add SwiftUI previews for each screen and state (loading, empty, error, filled).
