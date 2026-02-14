# PingKit

In-app feedback for iOS. Two lines of code. Zero dependencies.

[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-F05138.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16+-000000.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![SDK Size](https://img.shields.io/badge/Size-<50KB-green.svg)]()
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-0-orange.svg)]()

PingKit is an open-source in-app feedback SDK for iOS. Under 50 KB, zero dependencies, and your AI coding tools can query the feedback through MCP. The platform to triage, search, and act on feedback is \$9.99/mo flat.

> "We shipped Pingkit in Fastcruise in an afternoon." — [Fastcruise](https://apps.apple.com/us/app/fastcruise-for-teslamate/id6747918869) (TeslaMate companion app for iOS)

<!-- TODO: Add demo GIF showing feedback flow (~15s: tap feedback button → write message → attach screenshot → submit → appears in dashboard) -->

## Quick Start

### Install via SPM

**Xcode:** File → Add Package Dependencies → enter:

```
https://github.com/pingkitdev/pingkit-swift.git
```

**Or** add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pingkitdev/pingkit-swift.git", from: "1.0.0")
]
```

### Integrate

```swift
import PingKit

// Configure once at launch
PingKit.configure(apiKey: "pk_your_key")

// Show feedback anywhere
PingKit.show()
```

That's it. Get your API key from the [PingKit dashboard](https://pingkit.dev).

## Features

- 📦 **Two-line integration** — configure, show, done
- 📊 **Triage dashboard** — filter, search, and update status across app versions with built-in charts
- 🔔 **Webhook notifications** — Slack, Discord, email, or custom webhooks. Instant delivery.
- 🤖 **MCP server** — AI coding tools can read, search, and triage feedback without leaving the editor
- 🔒 **Privacy by default** — no analytics, no tracking, no background collection. Data flows only when the user taps Send.
- 🛡️ **Apple App Attest** — device attestation to verify feedback comes from real devices
- 📸 **Screenshots + metadata** — photo picker with EXIF stripping, plus auto-collected device info

## MCP Server

Your AI coding assistant can query user feedback while you code. Ask Claude Code to show unresolved bugs, or tell Cursor to mark feedback as resolved — without leaving your editor.

```
> "Show me unresolved feedback about the login screen"
> "What are users saying about v2.3.0?"
> "Acknowledge all feedback about dark mode, it's fixed"
```

Works with Claude Code, Cursor, Codex, Windsurf, and any tool that supports the Model Context Protocol.

PingKit is the only feedback SDK with MCP support.

**→ [Set up the MCP server](https://github.com/pingkitdev/pingkit-mcp)**

## Why PingKit?

- **Under 50 KB, zero dependencies** — doesn't bloat your binary
- **Open source (Apache 2.0)** — read every line before you ship it in your app
- **\$9.99/mo flat** — no MAU traps, no per-seat pricing, unlimited everything
- **MCP support** — your AI tools can read and triage feedback directly
- **Privacy-first** — no tracking, no analytics, no background collection
- **App Attest built in** — device verification out of the box

## Pricing

\$9.99/mo flat. No MAU traps. No per-seat pricing. Unlimited projects and feedback.

**→ [Sign up](https://pingkit.dev/signup)**

## Links

- [Website](https://pingkit.dev)
- [Documentation](https://pingkit.dev/docs)
- [Dashboard](https://pingkit.dev/feedback)
- [MCP Server](https://github.com/pingkitdev/pingkit-mcp)
- [Contact](mailto:hello@pingkit.dev)

## License

Apache 2.0. See [LICENSE](LICENSE) for details.
