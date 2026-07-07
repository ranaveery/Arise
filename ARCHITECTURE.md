# Arise Architecture

iOS SwiftUI gamified personal growth app. **7,839 lines** across 26 Swift files. No ViewModel layer, no reactive framework — views talk to Firestore directly.

---

## 1. Entrypoint & Routing

**`AriseApp.swift`** — `@main` struct. Registers `AppDelegate` for Firebase + Google Sign-In + portrait lock. Renders `AuthGateView` in `WindowGroup`.

**`AuthGateView`** — root router. Observes `Auth.auth().addStateDidChangeListener`:

| Auth State | Rendered View |
|---|---|
| Not logged in | `LandingView` / `SignUpView` (animated transition) |
| Logged in, not onboarded | `OnboardingView` |
| Logged in, onboarded | `MainTabView` |

> **Note:** `ContentView.swift` exists alongside `AuthGateView` with overlapping routing logic — appears to be a stale/legacy entrypoint. `AuthGateView` is the active root.

---

## 2. Major Screens

### Auth / Pre-onboarding (1,039 lines)
- **`LandingView`** (372 lines) — Google Sign-In, Apple Sign-In, links to email sign-up/login. Typing animation on taglines.
- **`SignUpView`** (275 lines) — email/password registration, Firestore user doc creation.
- **`LoginView`** (211 lines) — email/password login, also has Google Sign-In.

### Onboarding (1,618 lines — largest file)
- **`OnBoardingView`** — 11-step wizard (0–10). Collects: major focus/addiction, wake times (weekday/weekend), sleep duration, workout preferences, screen limit, weight/water, cold showers, activities, addiction severity, final note.
- Saves everything to `users/{uid}` in Firestore via `setData(merge: true)`.
- Also writes default skill data, rank, streak, and notification prefs.
- Has shared components: `DaysOfWeekPicker`, `OptionButton`, `SquareActionButton`.

### Main Tab (4 tabs)
Custom tab bar in `MainTabView` (no `UITabBarController`). Haptic on switch via `UIImpactFeedbackGenerator`. Animation toggle from `@AppStorage("animationsEnabled")`.

| Tab | View | Lines | Purpose |
|---|---|---|---|
| Home | `HomeView` | 533 | Rank card, 6 skill cards, XP progress bar |
| Tasks | `LoggingView` | 1,069 | Daily task generation + completion |
| Progress | `TrendsView` | 376 | Journey ring, streak/best/weak cards, spider chart |
| Settings | `SettingsView` | 649 | Account, notifications, appearance, app info, logout |

### Supporting Screens
- **`RankDetailsView`** (578 lines) — Current rank, next rank, skill contributions with progress bars, achievements grid.
- **`ChangePasswordView`** (178 lines) — 2-step reauth + update flow, includes password reset email.
- **`DeleteAccountView`** (566 lines) — Provider-aware reauth (Google/Apple/Email), Firestore doc deletion, Auth user deletion.
- **`ManagePreferencesView`** (436 lines) — Expandable sections to edit onboarding preferences.
- **Info pages**: `HelpCenterView`, `TermsOfUseView`, `PrivacyPolicyView` — all simple static layouts.
- **`ResetPasswordView`** — **TODO stub**, no implementation.

---

## 3. Data Layer

### Backend: Firebase
- **Auth**: Email/password, Google Sign-In (`GoogleSignIn-iOS`), Apple Sign-In (`ASAuthorization`)
- **Firestore**: Single collection `users/{uid}` per user
- **Real-time**: `addSnapshotListener` on `users/{uid}` doc for live XP/skill updates
- **Caching**: `UserDefaults.standard` stores `cachedUserData` dictionary and individual keys

### Firestore Document Schema — `users/{uid}`

```
{
  uid, name, email: String
  rank: "Seeker", xp: Int, streak: Int, lastStreakDate: "yyyy-MM-dd"
  isOnboarded: Bool, animationsEnabled: Bool
  majorFocus: String, addictionDaysPerWeek: Int
  wakeWeekday: Int (military), wakeWeekend: Int
  sleepHoursWeekday: Double, sleepHoursWeekend: Double
  workoutHoursPerDay: Double, workoutDays: [Int]
  screenLimitHours: Double, weightLbs: Int, waterOunces: Int
  coldShowerDays: [Int], takeColdShowers: Bool
  selectedActivities: { "meditation": [1,3,5], ... }
  finalNote: String
  completedTasks: ["2026-07-06|Arise and Shine|...", ...]
  notifications: { expiringTasks: Bool, newTasks: Bool, sleepTime: Bool }
  skills: {
    "Discipline": { xp: Int, level: Int },
    "Fitness": { xp: Int, level: Int },
    "Fuel": {}, "Wisdom": {}, "Resilience": {}, "Network": {}
  }
  achievements: {
    "1": { unlocked: Bool, unlockedDate: "Jul 2026" },
    ...
  }
}
```

### Data Access Pattern
All views import `FirebaseAuth` / `FirebaseFirestore` and query directly:

```swift
Firestore.firestore().collection("users").document(uid)
    .addSnapshotListener { snapshot, error in ... }
    .getDocument { ... }
    .updateData([...])
    .setData([...], merge: true)
```

---

## 4. Gamification System

### Ranks (10 tiers)
Defined in `HomeView.swift` and duplicated in `RankDetailsView.swift`.

| # | Name | XP Required |
|---|---|---|
| 1 | Seeker | 0 |
| 2 | Initiate | 900 |
| 3 | Pioneer | 2,100 |
| 4 | Explorer | 3,000 |
| 5 | Challenger | 5,100 |
| 6 | Refiner | 6,900 |
| 7 | Master | 9,000 |
| 8 | Conquerer | 12,000 |
| 9 | Ascendant | 15,000 |
| 10 | Transcendent | 20,100 |

### Skills (6)
`Models.swift` defines `SkillXP` and global `skillLevelThresholds`. Each skill has 10 levels.

| Skill | Icon | Max XP |
|---|---|---|
| Resilience | `brain` | 3,350 |
| Fuel | `fork.knife` | 3,350 |
| Fitness | `figure.run` | 3,350 |
| Wisdom | `book.fill` | 3,350 |
| Discipline | `infinity` | 3,350 |
| Network | `person.2.fill` | 3,350 |

Level thresholds: `[0, 150, 350, 500, 850, 1150, 1500, 2000, 2500, 3350]`

### Achievements (16)
`RankDetailsView.swift` defines 16 achievements. 9 tied to rank milestones, 1 for earning first XP, 6 for reaching level 10 in each skill.

---

## 5. Task System (`LoggingView`)

Daily tasks are **generated client-side** based on user preferences from Firestore.

### Task Types
- **Daily**: Wake up ("Arise and Shine"), Bedtime, Water Intake, Screen Time Limit, Social Interaction
- **Set Day**: Workout, Cold Shower, custom activities (meditation, reading, pray, study, walk, run)
- **Weekly** (Saturday only): Meet Someone New
- **Addiction**: Based on `majorFocus` + `addictionDaysPerWeek`

### Task Mechanics
- Deterministic IDs (`yyyy-MM-dd|name|description`) so task identity is stable across reloads
- XP distributed among `skillTargets` (even split + remainder)
- Partial completion awards 50% XP (rounded down to nearest 5)
- All tasks expire at midnight
- Midnight reset (via `Timer.publish(every: 60, on:...)` + `scenePhase` monitoring)
- Streak increments when all tasks completed — checks `lastStreakDate` continuity

---

## 6. Notifications

Local notifications fired from `SettingsView` via `UNUserNotificationCenter`.

| Notification | Time | Condition |
|---|---|---|
| Expiring Tasks | 18:00 | `expiringTasks` toggle |
| Bedtime Reminder | 30 min before bedtime | `sleepTime` toggle, calculated from wake + sleep hours |
| New Tasks | 30 min after wake time | `newTasks` toggle |

Preferences stored in Firestore under `notifications` sub-document.

---

## 7. Shared UI Patterns

- **Brand gradient**: `Color(red: 84/255, green: 0/255, blue: 232/255)` → `Color(red: 236/255, green: 71/255, blue: 1/255)` — used in 12+ files, **no shared constant**
- **`SectionCard`**: Reusable grouped card in `SettingsView`
- **`SquareActionButton`**: Gradient CTA button in `OnBoardingView`
- **`OptionButton`**: Selectable grid item with icon in `OnBoardingView`
- **`DaysOfWeekPicker`**: M/T/W/T/F/S/S selection in `OnBoardingView`, `ManagePreferencesView`
- **`SkillCardView`**: Reusable skill card with tinted icon, progress bar, level badge
- **`TaskCard`**: Expandable task card with complete/partial actions
- **`SpiderChart`**: Radar chart for 6-skill visualization in `TrendsView`
- **`JourneyProgressRing`**: Circular XP progress in `TrendsView`
- **`AchievementCard`**: Grid item for locked/unlocked achievements
- **`EditButton`** (custom): Inline text field with commit action in `SettingsView`
- **`TopRoundedRectangle`**: Shape for bottom sheet-style containers in `LandingView`
- **Safe subscript extension**: `Array[safe: index]` defined in `HomeView.swift`

---

## 8. Auth Provider Handling

Three sign-in methods, each writing to Firestore on first sign-in:

| Provider | File | Reauth for Delete |
|---|---|---|
| Email/password | `SignUpView`, `LoginView` | UIAlertController for password |
| Google | `LandingView` | `GIDSignIn.sharedInstance.signIn(withPresenting:)` |
| Apple | `LandingView` | `ASAuthorizationController` via `AppleSignInCoordinator` |

`AppleSignInCoordinator` (`DeleteAccountView.swift`) is a standalone `NSObject` coordinator class for the async Apple reauth flow during account deletion.

---

## 9. Code Duplication & Quirks

- `skillLevelThresholds` defined in 3 places: `Models.swift` (global), `HomeView.swift`, `RankDetailsView.swift`
- `ranks` array duplicated in `HomeView.swift` and `RankDetailsView.swift`
- `calculateSkillLevel`, `skillProgress` functions duplicated across `HomeView.swift`, `TrendsView.swift`
- `militaryTimeInt`, `calculateBedtime`, `timeFromMilitaryInt`, `isoDateString` — duplicated across `OnBoardingView.swift`, `LoggingView.swift`, `SettingsView.swift`, `ManagePreferencesView.swift`
- `TabButtonView.swift` exists as separate file but `MainTabView.swift` has its own inline `TabButton`
- `ResetPasswordView.swift` is a **TODO stub** with no implementation
- `TermsAndPrivacy.txt` (100 lines) is not referenced by any Swift file
- `GIDClientID` + `CFBundleURLSchemes` hardcoded in `Info.plist`
- `GoogleService-Info.plist` tracked in git

---

## 10. Dependencies (SPM)

| Package | Version | Products Used |
|---|---|---|
| `firebase-ios-sdk` | ~> 12.0 | Analytics, Auth, Firestore, Core |
| `GoogleSignIn-iOS` | ~> 9.0 | GoogleSignIn |

---

## 11. Build Config

- **Deployment target**: iOS 18.6
- **Device family**: iPhone only (`TARGETED_DEVICE_FAMILY = 1`)
- **Mac Catalyst**: disabled
- **iPad**: disabled
- **Orientation**: Portrait-locked (code-level in `AppDelegate`)
- **Category**: Health & Fitness
- **Version**: 1.0.3, build 1
- **Team**: `D3338RFMNC` (automatic signing)

---

## 12. Tests

| Target | Framework | Status |
|---|---|---|
| `AriseTests` | Swift Testing (`@Test`, `#expect`) | Placeholder only |
| `AriseUITests` | XCTest | Placeholder only |

Run both via `Cmd+U` in Xcode.
