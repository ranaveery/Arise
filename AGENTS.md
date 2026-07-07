# Arise — Agent Guide

## Project

iOS SwiftUI gamified personal growth app. Xcode-only project (no SwiftPM CLI, no CocoaPods).

## Build & Run

Open `Arise.xcodeproj` in Xcode 16+ (deployment target iOS 18.6). Select a **iPhone 16 Pro Simulator or later** — iPad and Mac Catalyst are explicitly disabled.

Run with `Cmd+R` on the `Arise` scheme. Tests with `Cmd+U`.

- **Unit tests**: `AriseTests` target, use Swift Testing (`import Testing`, `@Test`, `#expect`).
- **UI tests**: `AriseUITests` target, use XCTest.

## Key Dependencies (SPM)

- `firebase-ios-sdk` ~> 12.0 (Analytics, Auth, Firestore, Core)
- `GoogleSignIn-iOS` ~> 9.0

`GoogleService-Info.plist` (Firebase) and `Info.plist` (Google Sign-In URL scheme) are required at build time. The test targets explicitly exclude `GoogleService-Info.plist` from synchronization.

## Architecture

**Entrypoint**: `AriseApp.swift` → `AuthGateView` → routes:
- Not logged in → `LandingView` / `SignUpView`
- Logged in, not onboarded → `OnboardingView`
- Logged in, onboarded → `MainTabView` (4 tabs: Home, Tasks/Logging, Progress/Trends, Settings)

**Pattern**: SwiftUI views, no view-model layer. Firebase Firestore accessed directly from views. Auth state via `Auth.auth().addStateDidChangeListener`.

## App Config

- **Bundle ID**: `com.ranaveer.Arise`
- **Version**: `1.1.0` (Current: 1) — **Clean build (Cmd+Shift+K) required after changing** `MARKETING_VERSION` in Xcode; incremental builds may not regenerate Info.plist
- **Team**: `D3338RFMNC` — automatic code signing
- **Orientation**: Portrait-locked via `AppDelegate.supportedInterfaceOrientationsFor`
- **Category**: Health & Fitness (`public.app-category.healthcare-fitness`)
- **Accent color**: `AccentColor` in Assets.xcassets

## Style Notes

- No lint/format config or tooling. Follow existing code conventions.
- Custom tab bar in `MainTabView.swift` (no system tab bar). Tab icons use `.fill` variant when selected.
- Haptic feedback on tab switches (`UIImpactFeedbackGenerator`).
- Animations toggle stored in `@AppStorage("animationsEnabled")`.

## Git

- Version tag pattern: semver (e.g., `1.0.2`, `0.9.9.3`).
- `GoogleService-Info.plist` is tracked in git (not in `.gitignore`).
