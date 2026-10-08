//
//  ProPromptTracker.swift
//  Arise
//
//  Decides when the non-intrusive Arise Pro soft prompt may appear.
//
//  Rules (mirrors the product spec):
//  - Presented only at the moment a rank-up celebration is dismissed.
//  - Requires the user to have reached the first 3-day streak.
//  - At most once per 7 days.
//  - At most once per session.
//  - Never shown to Pro users.
//

import Foundation

enum ProPromptTracker {

    private static let firstThreeDayStreakKey = "proPromptFirstThreeDayStreak"
    private static let lastPromptShownAtKey = "proPromptLastShownAt"
    private static let sevenDays: TimeInterval = 7 * 24 * 60 * 60

    // In-memory on purpose: resets every launch, which is what "per session" means.
    private static var promptShownThisSession = false

    static var hasFirstThreeDayStreak: Bool {
        UserDefaults.standard.bool(forKey: firstThreeDayStreakKey)
    }

    /// Call whenever the current streak is known so the first 3-day streak
    /// milestone can be persisted once.
    static func recordStreakIfNeeded(_ streak: Int) {
        guard !hasFirstThreeDayStreak else { return }
        if streak >= 3 {
            UserDefaults.standard.set(true, forKey: firstThreeDayStreakKey)
        }
    }

    /// Whether the soft prompt may appear right now.
    static func shouldPresentSoftPrompt(isPro: Bool, now: Date = Date()) -> Bool {
        shouldPresent(
            isPro: isPro,
            hasThreeDayStreak: hasFirstThreeDayStreak,
            shownThisSession: promptShownThisSession,
            lastShownAt: UserDefaults.standard.object(forKey: lastPromptShownAtKey) as? Date,
            now: now
        )
    }

    /// Pure throttle rule, injectable for tests.
    static func shouldPresent(
        isPro: Bool,
        hasThreeDayStreak: Bool,
        shownThisSession: Bool,
        lastShownAt: Date?,
        now: Date
    ) -> Bool {
        guard !isPro else { return false }
        guard hasThreeDayStreak else { return false }
        guard !shownThisSession else { return false }

        if let lastShown = lastShownAt, now.timeIntervalSince(lastShown) < sevenDays {
            return false
        }
        return true
    }

    /// Call when the soft prompt is actually shown so the 7-day and per-session
    /// throttles take effect.
    static func markPromptShown(at date: Date = Date()) {
        promptShownThisSession = true
        UserDefaults.standard.set(date, forKey: lastPromptShownAtKey)
    }
}