//
//  ProPromptTrackerTests.swift
//  AriseTests
//
//  Tests for the pure Arise Pro soft-prompt throttle rule.
//

import Testing
import Foundation
@testable import Arise

struct ProPromptTrackerTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func proUsersNeverReceiveSoftPrompt() {
        #expect(ProPromptTracker.shouldPresent(
            isPro: true,
            hasThreeDayStreak: true,
            shownThisSession: false,
            lastShownAt: nil,
            now: now
        ) == false)
    }

    @Test func requiresFirstThreeDayStreak() {
        #expect(ProPromptTracker.shouldPresent(
            isPro: false,
            hasThreeDayStreak: false,
            shownThisSession: false,
            lastShownAt: nil,
            now: now
        ) == false)
    }

    @Test func neverMoreThanOncePerSession() {
        #expect(ProPromptTracker.shouldPresent(
            isPro: false,
            hasThreeDayStreak: true,
            shownThisSession: true,
            lastShownAt: nil,
            now: now
        ) == false)
    }

    @Test func presentsWhenEligible() {
        #expect(ProPromptTracker.shouldPresent(
            isPro: false,
            hasThreeDayStreak: true,
            shownThisSession: false,
            lastShownAt: nil,
            now: now
        ) == true)
    }

    @Test func throttledWithinSevenDays() {
        let sixDaysAgo = now.addingTimeInterval(-(6 * 24 * 60 * 60))
        #expect(ProPromptTracker.shouldPresent(
            isPro: false,
            hasThreeDayStreak: true,
            shownThisSession: false,
            lastShownAt: sixDaysAgo,
            now: now
        ) == false)
    }

    @Test func allowedAtExactlySevenDays() {
        let sevenDaysAgo = now.addingTimeInterval(-(7 * 24 * 60 * 60))
        #expect(ProPromptTracker.shouldPresent(
            isPro: false,
            hasThreeDayStreak: true,
            shownThisSession: false,
            lastShownAt: sevenDaysAgo,
            now: now
        ) == true)
    }

    @Test func allowedAfterSevenDays() {
        let tenDaysAgo = now.addingTimeInterval(-(10 * 24 * 60 * 60))
        #expect(ProPromptTracker.shouldPresent(
            isPro: false,
            hasThreeDayStreak: true,
            shownThisSession: false,
            lastShownAt: tenDaysAgo,
            now: now
        ) == true)
    }
}