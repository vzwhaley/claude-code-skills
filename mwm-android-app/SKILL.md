---
name: mwm-android-app
description: Moon Whale Media house conventions for building Android apps (Kotlin, Jetpack Compose, Material 3). Use whenever creating a new Android app, adding an Android client to a product, or making significant changes to any *-android project — covers project setup, signing, API client, token storage, branding, and ads.
---

# Moon Whale Media — Android App Conventions

These are the proven conventions shared by AstrologerFlow, FileManagerFlow, MyEmergencyScreen, NewsroomFlow, and TheCardbackCantina Android apps. Follow them for every new Android app unless the user says otherwise.

## Stack (non-negotiable defaults)

- **Repo:** the app lives in the product's single monorepo as the `<slug>-android/` folder and is committed on `main` with the rest of the product (see the Repository rules in `mwm-new-product`). Never give it its own GitHub repo or `.git`, and don't create branches.
- **Kotlin + Jetpack Compose + Material 3.** No XML layouts for app UI (XML only for launcher icons, the boot `themes.xml`, and AppWidget RemoteViews). No Fragments, no View system, no data binding.
- **minSdk = 26**, targetSdk/compileSdk = current stable. `JavaVersion.VERSION_17` / `jvmTarget = "17"`.
- **Gradle version catalogs** (`gradle/libs.versions.toml` + `alias(libs.plugins.…)`). Use the standard `settings.gradle.kts` (google() `includeGroupByRegex` filter, `FAIL_ON_PROJECT_REPOS`), differing only in `rootProject.name`.
- **Package / applicationId: `com.moonwhale.<app>`** (standardized 2026-08; older apps drift — don't copy their IDs). Debug builds get `applicationIdSuffix = ".dev"`.
- **No flavors** — only `debug`/`release` build types.
- **DI: hand-rolled `ServiceLocator` singleton** in `data/ServiceLocator.kt`. Resist Hilt/Dagger/Koin until wiring is actually complex. There is no Hilt, Room, Moshi, or Gson anywhere in the house stack.

## House dependencies

- Retrofit + `retrofit2-kotlinx-serialization-converter` + kotlinx-serialization-json + OkHttp + logging-interceptor
- Compose BOM + material3 + material-icons-extended + navigation-compose
- `androidx.datastore:datastore-preferences` for non-sensitive prefs; `androidx.security:security-crypto` (EncryptedSharedPreferences) for the auth token
- Coil (`coil-compose`) for images
- AdMob `play-services-ads` for free tiers (+ `user-messaging-platform` for GDPR/UMP consent)
- Billing: **none in the app** - see the `mwm-billing-standard` skill. Pro is sold only on the website; the app is a free download, never includes RevenueCat / Play Billing `billing-ktx` / `com.android.vending.BILLING`, and hides all purchase UI unless the server's `capabilities.purchase_links` is true
- Firebase messaging only if push is needed — gate the plugin: `if (file("google-services.json").exists()) { apply(plugin = …) }`

## Signing — keystore.properties pattern

Release signing loads from `keystore.properties` at repo root (gitignored, with a committed `keystore.properties.example`). **Never fail the build when the keystore is absent** — fall back to debug signing with a warning:

```kotlin
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) FileInputStream(keystorePropertiesFile).use { load(it) }
}
val hasReleaseKeystore = keystorePropertiesFile.exists() &&
    keystoreProperties.getProperty("storeFile")?.isNotBlank() == true
// release { signingConfig = if (hasReleaseKeystore) releaseConfig else debug + logger.warn("⚠️ NOT shippable") }
```

For CI, add env-var fallbacks: `fun signingValue(key: String, env: String) = keystoreProperties.getProperty(key)?.takeIf { it.isNotBlank() } ?: System.getenv(env)` with `<APP>_KEYSTORE_FILE` / `_KEYSTORE_PASSWORD` / `_KEY_ALIAS` / `_KEY_PASSWORD`.

**BuildConfig gotcha:** BuildConfig is generated as Java where `\$` is an illegal escape — do NOT escape dollar signs in `buildConfigField` strings (a `$` in a test password would break every debug build with a cryptic error in generated code).

## API client (talks to the product's Laravel backend)

- Auth is **Laravel Sanctum personal access tokens** — `POST /auth/login` returns `plainTextToken`; store it in EncryptedSharedPreferences (`MasterKey.KeyScheme.AES256_GCM`) via a `TokenStore` object. Widget-bearing apps mirror the token into shared storage for the widget.
- Retrofit interface named `<Product>Api` in `data/Api.kt`. JSON config copy-pasted everywhere on purpose: `Json { ignoreUnknownKeys = true; isLenient = true; explicitNulls = false }`.
- `AuthInterceptor` reads the token fresh on every call:

```kotlin
class AuthInterceptor(private val tokenProvider: () -> String?) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): okhttp3.Response {
        val builder = chain.request().newBuilder().header("Accept", "application/json")
        tokenProvider()?.takeIf { it.isNotEmpty() }?.let { builder.header("Authorization", "Bearer $it") }
        return chain.proceed(builder.build())
    }
}
```

- Logging interceptor: `BASIC`/`HEADERS` in debug, `NONE` in release, and `redactHeader("Authorization")`.
- Base URLs are build-time constants: `buildConfigField("String", "API_BASE_URL", …)` — release = production HTTPS. **Debug talks to Herd** (the website always runs on Herd at `https://<slug>.test` - global CLAUDE.md rule): the emulator can't resolve `*.test`, so the debug build sets `API_BASE_URL = "https://<slug>.test"`, gives OkHttp a DEBUG-only `Dns` that maps `<slug>.test` to `10.0.2.2` (the host), and trusts Herd's local CA through `src/debug/res/xml/network_security_config.xml` (`<certificates src="@raw/herd_ca"/>`, the CA exported from Herd). Release keeps HTTPS-only + system CAs. For a physical device, map to the PC's LAN IP. Only if that isn't wired up yet: a temporary `php artisan serve --host=0.0.0.0` at `http://10.0.2.2:<port>` for the emulator run - say so and stop it afterwards. A runtime override behind a Settings → Developer screen is a nice-to-have (see FileManagerFlow's rebuildable `ApiClient.setBaseUrl()`).
- **Ad config comes from the server**: `GET /api/config` returns AdMob unit IDs for Free users and `ads.show=false, units=null` for Pro. Never hardcode unit IDs client-side beyond the AdMob app ID, and never ship unit IDs to Pro clients.
- **Store billing switch:** send `platform=android` to the config endpoint and read `capabilities.purchase_links` (default false) and `capabilities.manage_billing`. While false: no "Upgrade to Pro" / "Go Pro" / prices / pricing links - locked features show neutral text; "Manage Billing" only when `manage_billing`. Website URLs the app opens get `?from=app&platform=android`. `POST /api/auth/web-handoff` (single-use 5-minute token) may open account pages signed in, never checkout while the switch is off. Reference: IdentiFlow Android `Session` / `UpgradePrompt`.

## Branding & theming

- **Spantaran font** (`app/src/main/res/font/spantaran.ttf`) is used ONLY for the "by Moon Whale Media, LLC" tagline: `val BrandFont = FontFamily(Font(R.font.spantaran))`. Body text stays system default. The logo lockup always includes the tagline (see [[moon-whale-media-house-style]] conventions).
- **Draw the logo in code**, not as a bitmap — a Compose `Canvas` `BrandLogo.kt` component that visually matches the launcher adaptive icon.
- **Launcher icons are vector adaptive icons**: `mipmap-anydpi-v26/ic_launcher.xml` + `drawable/ic_launcher_foreground.xml` + background. Include a `<monochrome>` layer for themed icons.
- **No splash-screen library.** Boot `themes.xml` sets `android:windowBackground` + `android:statusBarColor` to brand colors under `Theme.Material.NoActionBar`; Compose drives the real theming.
- `ui/theme/Theme.kt` color tokens mirror the product website's Tailwind palette by hex, with the source noted in a comment (e.g. `// mirrors text-indigo-600 from the web app`).

## Dev-loop tooling (put in the monorepo's build-tools/)

- Parameterize `adb` path and device serial — never hardcode them.
- Useful scripts to replicate from FileManagerFlow/NewsroomFlow build-tools: icon generation via PowerShell + System.Drawing (no ImageMagick), `capture-android.ps1` (screencap → pull → web /help images), reset-and-reinstall dev loop that preserves the auth token and refuses to run if sources are newer than the APK.
- Keep the standing rule: build-tools holds helper scripts only — each app builds with its own standard tooling inside its own directory.
