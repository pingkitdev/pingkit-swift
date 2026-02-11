# PingKit

Lightweight, privacy-first in-app feedback SDK for iOS.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16+-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Collect text feedback and screenshots from your iOS app in two lines of code. No dependencies, no tracking, no bloat.

```swift
PingKit.configure(apiKey: "pk_proj_xxxxxxxxxxxx")
PingKit.show()
```

## Features

- **Two-line integration** — configure and show
- **Zero dependencies** — pure Swift + Apple frameworks
- **Privacy-first** — no auto-screenshots, no tracking, user chooses what to share
- **Native UI** — SwiftUI modal that respects dark mode, Dynamic Type, and system colors
- **Screenshot support** — optional photo picker, JPEG compression, multipart upload
- **Device metadata** — auto-collects device model, OS version, app version, locale
- **Apple App Attest** — device verification to prevent abuse
- **Headless mode** — bring your own UI, use PingKit for transport
- **Themeable** — match your app's accent color, background, corner radius, and font

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add PingKit to your project in Xcode:

1. **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/pingkitdev/pingkit-swift.git
   ```
3. Select **Up to Next Major Version** starting from `1.0.0`

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pingkitdev/pingkit-swift.git", from: "1.0.0")
]
```

## Quick Start

### 1. Configure

Call `configure` once at app launch — in your `App` init or `AppDelegate`:

```swift
import PingKit

@main
struct MyApp: App {
    init() {
        PingKit.configure(apiKey: "pk_proj_xxxxxxxxxxxx")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Get your API key from the [PingKit dashboard](https://app.pingkit.dev).

### 2. Show the Feedback Modal

Trigger the modal from anywhere — a button, a shake gesture, a menu item:

```swift
Button("Send Feedback") {
    PingKit.show()
}
```

That's it. The modal handles text input, screenshot attachment, metadata collection, and submission.

## Usage

### Basic

```swift
// Show with custom metadata
PingKit.show(metadata: ["screen": "settings"])
```

### Email Field

```swift
// Optional email field
PingKit.show(email: .optional)

// Required email field
PingKit.show(email: .required)

// Pre-filled email
PingKit.show(email: .prefilled("user@example.com"))
```

### Category Picker

```swift
// Show a type/category picker
PingKit.show(type: .picker(["Bug", "Feature Request", "Question"]))
```

### Combine Options

```swift
PingKit.show(
    email: .optional,
    type: .picker(["Bug", "Feature", "Other"]),
    metadata: ["screen": "checkout", "user_tier": "premium"]
)
```

### Theming

Customize the modal's appearance to match your app:

```swift
PingKit.configure(
    apiKey: "pk_proj_xxxxxxxxxxxx",
    theme: PingKitTheme(
        accentColor: .blue,
        backgroundColor: Color(uiColor: .systemBackground),
        cornerRadius: 16,
        font: .body
    )
)
```

| Property | Default | Description |
|----------|---------|-------------|
| `accentColor` | `.accentColor` | Buttons and interactive elements |
| `backgroundColor` | `.systemBackground` | Modal background |
| `cornerRadius` | `20` | Modal corner radius |
| `font` | `.body` | Font used in the modal |

### Headless Mode

Skip the built-in UI entirely. Use PingKit as a transport layer with your own feedback form:

```swift
do {
    let result = try await PingKit.submit(
        text: "The save button doesn't work",
        image: screenshotData,       // optional Data?
        email: "user@example.com",   // optional String?
        type: "bug",                 // optional String?
        metadata: ["screen": "editor"]
    )
    print("Feedback submitted: \(result.id)")
} catch {
    print("Submission failed: \(error)")
}
```

### Configuration Options

```swift
PingKit.configure(
    apiKey: "pk_proj_xxxxxxxxxxxx",
    options: PingKitOptions(
        endpoint: "https://app.pingkit.dev",  // Custom endpoint
        enableAppAttest: true,                 // Device verification (default: true)
        maxImageSizeMB: 5                      // Max image size before compression (default: 5)
    )
)
```

## Auto-Collected Metadata

Every submission automatically includes device context (users are informed via an expandable info pill in the modal):

| Field | Example |
|-------|---------|
| Device model | iPhone 15 Pro |
| OS version | 18.2 |
| App version | 1.2.0 |
| Build number | 42 |
| Locale | en_US |
| Timezone | Europe/Zurich |

## Error Handling

PingKit never crashes your app. All errors are handled gracefully:

- **Network errors** — inline retry prompt in the modal
- **Rate limited** — "Too many submissions, try again later"
- **Invalid API key** — generic error to user, warning logged to console
- **Calling `show()` before `configure()`** — no-op with console warning

When using headless mode, errors are thrown as `PingKitError`:

```swift
do {
    try await PingKit.submit(text: "feedback")
} catch PingKitError.rateLimited(let retryAfter) {
    // Handle rate limiting
} catch PingKitError.unauthorized {
    // Invalid API key
} catch PingKitError.planLimitReached {
    // Monthly quota exceeded
} catch {
    // Other errors
}
```

## App Attest

PingKit uses [Apple App Attest](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity) to verify that feedback comes from real iOS devices. This is enabled by default and works transparently:

1. On first launch, PingKit registers a key with Apple's App Attest service
2. On each submission, an assertion is generated and sent with the request
3. The server validates the assertion before accepting feedback

On devices where App Attest isn't available (simulators, older devices), feedback is still accepted but may be subject to stricter rate limits.

To disable:

```swift
PingKit.configure(
    apiKey: "pk_proj_xxxxxxxxxxxx",
    options: PingKitOptions(enableAppAttest: false)
)
```

## Privacy

PingKit is designed with privacy as a core principle:

- **No auto-screenshots** — users explicitly choose to attach an image
- **No tracking** — no analytics, no fingerprinting, no third-party SDKs
- **Transparent metadata** — users can see exactly what device info is collected
- **User-initiated only** — feedback is never sent without the user pressing "Send"
- **Open source** — audit every line of code that ships in your app

## License

Apache 2.0. See [LICENSE](LICENSE) for details.
