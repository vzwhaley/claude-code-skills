---
name: mwm-ios-app
description: Moon Whale Media house conventions for building iOS apps (SwiftUI, XcodeGen, SPM-minimal). Use whenever creating a new iOS app, adding an iOS client to a product, or making significant changes to any *-ios project — covers project generation, API client, Keychain token storage, billing, and branding.
---

# Moon Whale Media — iOS App Conventions

Proven conventions shared by the AstrologerFlow, FileManagerFlow, MyEmergencyScreen, NewsroomFlow, and TheCardbackCantina iOS apps. Follow them for every new iOS app unless the user says otherwise.

## Stack (non-negotiable defaults)

- **100% SwiftUI, zero UIKit** — the only exceptions are `UIViewRepresentable` wrappers when a framework demands it (AdMob banners, AVFoundation camera/scanning).
- **MVVM**: one `ObservableObject` per screen for content-heavy apps, or a single `AppState` for small apps.
- **Min iOS 16.0** (17.0 if a needed API requires it). Swift 5.x.
- **Project generation: XcodeGen `project.yml`, committed; `.xcodeproj` NOT committed** (preferred for new apps). If a project must hand-author its `.xcodeproj` (Xcode 16 `fileSystemSynchronizedGroups`), add a `validate-pbxproj.py` checker to build-tools (balanced braces, matched Begin/End markers, no dangling object IDs) and run it after every hand edit.
- **Bundle ID: `com.moonwhale.<app>`** (standardized 2026-08; older apps drift). Widget extension target: `<bundleid>.widget`. App Group: `group.<bundleid>`. Test target: `<bundleid>.tests`.
- **SPM only, and only when unavoidable.** House policy (from FileManagerFlow's Api.swift): *no third-party HTTP library on purpose — keeps the App Store binary small and avoids supply-chain surface.* Three of five shipping apps have zero third-party packages.
- **DI: hand-rolled `ServiceLocator` singleton** in `Services/ServiceLocator.swift`, mirroring the Android one. Resist Resolver/Factory/Swinject until the wiring is actually complex.

## API client (talks to the product's Laravel backend)

- Plain **`URLSession` + `async/await` + `Codable`** with `keyDecodingStrategy = .convertFromSnakeCase` / `keyEncodingStrategy = .convertToSnakeCase`.
- The client **mirrors the Android Retrofit interface method-for-method** — same endpoint list, same names — so the two clients stay reviewable side by side. If useful, reimplement Retrofit's `Response<T>` shape: `struct ApiResponse<T> { statusCode; body; errorBody; var isSuccessful }`.
- Auth is **Laravel Sanctum tokens**: `POST /auth/login` returns a plain-text token.
- **Token storage: Keychain** `kSecClassGenericPassword`, `service = <bundle id>`, `account = "api-token"`, `kSecAttrAccessibleAfterFirstUnlock`. Widget-bearing apps mirror the token into the App Group.
- Base URL: `#if DEBUG` in a `Config`/`AppConfig` enum — debug = `http://localhost:<port>` with `NSAllowsLocalNetworking: true` in Info.plist, release = production HTTPS.
- **Ad config comes from the server**: `GET /api/config` returns ad unit IDs for Free users, `ads.show=false` for Pro. Never ship unit IDs to Pro clients.
- "Upgrade to Pro" opens the website already logged in via `POST /api/auth/web-handoff` (single-use 5-minute token).

## Billing

Prefer, in order:
1. **Web checkout** (no IAP at all) — the default for utility apps where Apple's rules allow it.
2. **Raw StoreKit 2** — `Product.products(for:)`, then POST the JWS transaction to the backend's `/billing/apple/verify`; **the server is the entitlement source of truth** (see MyEmergencyScreen's `Store.swift`).
3. **RevenueCat** (`purchases-ios` via SPM) only when cross-platform subscription management is genuinely needed — and gate on an empty API key so the app falls back to web checkout.

## Branding & UI

- **Spantaran font** (`App/Spantaran.ttf`) used ONLY for the "by Moon Whale Media, LLC" tagline; body text stays system fonts. The logo lockup always includes the tagline.
- **Draw the logo in SwiftUI code** (`Views/BrandLogo.swift` / `BrandHeader.swift`), not as a bitmap — visually identical to the app icon.
- **No launch storyboard** — `UILaunchScreen: {}` in Info.plist; brand background color only.
- Color tokens in `Brand.swift` / theme file **mirror the product website's Tailwind palette by hex**, with the source noted in a comment ("matches web + Android").
- AdMob via SPM `swift-package-manager-google-mobile-ads` when the free tier shows ads; pin the major version and note symbol-rename hazards when upgrading majors.

## Dev-loop notes

- XcodeGen regenerates the project: `xcodegen generate` after editing `project.yml`.
- Keep endpoint parity with Android — when adding an endpoint on one platform, add it to the other (and the Laravel `routes/api.php`) in the same session.
