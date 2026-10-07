//
//  ProEntitlementTests.swift
//  AriseTests
//

import Foundation
import Testing
@testable import Arise

struct ProEntitlementTests {

    // MARK: - Configuration guard

    @Test("Grandfather dates are configured")
    func grandfatherDatesAreConfigured() {
        #expect(ProConfig.grandfatherDatesAreConfigured,
                "Set PAID_ERA_START and PAID_ERA_END in ProConfig.swift")
    }

    @Test("Grandfather start is before end")
    func grandfatherStartIsBeforeEnd() {
        guard ProConfig.grandfatherDatesAreConfigured else {
            Issue.record("Set PAID_ERA_START and PAID_ERA_END in ProConfig.swift")
            return
        }
        #expect(ProConfig.paidEraStart! < ProConfig.paidEraEnd!)
    }

    // MARK: - Grandfathering boundary rule (pure function)

    @Test("One day before start is not grandfathered")
    func beforeStart() {
        let start = Self.date("2026-08-01T00:00:00Z")
        let end = Self.date("2026-11-01T00:00:00Z")
        let purchase = start.addingTimeInterval(-24 * 3600)
        #expect(!ProConfig.isGrandfathered(paidEraStart: start, paidEraEnd: end, originalPurchaseDate: purchase))
    }

    @Test("Exactly at start is grandfathered")
    func atStart() {
        let start = Self.date("2026-08-01T00:00:00Z")
        let end = Self.date("2026-11-01T00:00:00Z")
        #expect(ProConfig.isGrandfathered(paidEraStart: start, paidEraEnd: end, originalPurchaseDate: start))
    }

    @Test("Inside the window is grandfathered")
    func insideWindow() {
        let start = Self.date("2026-08-01T00:00:00Z")
        let end = Self.date("2026-11-01T00:00:00Z")
        let purchase = Self.date("2026-09-15T12:00:00Z")
        #expect(ProConfig.isGrandfathered(paidEraStart: start, paidEraEnd: end, originalPurchaseDate: purchase))
    }

    @Test("Exactly at end is not grandfathered")
    func atEnd() {
        let start = Self.date("2026-08-01T00:00:00Z")
        let end = Self.date("2026-11-01T00:00:00Z")
        #expect(!ProConfig.isGrandfathered(paidEraStart: start, paidEraEnd: end, originalPurchaseDate: end))
    }

    @Test("After end is not grandfathered")
    func afterEnd() {
        let start = Self.date("2026-08-01T00:00:00Z")
        let end = Self.date("2026-11-01T00:00:00Z")
        let purchase = end.addingTimeInterval(24 * 3600)
        #expect(!ProConfig.isGrandfathered(paidEraStart: start, paidEraEnd: end, originalPurchaseDate: purchase))
    }

    @Test("Unconfigured window never grandfathers")
    func unconfiguredWindowNeverGrants() {
        #expect(!ProConfig.isGrandfathered(paidEraStart: nil, paidEraEnd: nil, originalPurchaseDate: Self.date("2026-09-15T12:00:00Z")))
    }

    @Test("Inverted window never grandfathers")
    func invertedWindowNeverGrants() {
        let start = Self.date("2026-11-01T00:00:00Z")
        let end = Self.date("2026-08-01T00:00:00Z")
        #expect(!ProConfig.isGrandfathered(paidEraStart: start, paidEraEnd: end, originalPurchaseDate: Self.date("2026-09-15T12:00:00Z")))
    }

    // MARK: - isPro truth table

    @Test("isPro truth table")
    func isProTruthTable() {
        #expect(!ProStatus.loading.isPro)
        #expect(!ProStatus.free.isPro)
        #expect(ProStatus.purchased.isPro)
        #expect(ProStatus.grandfathered.isPro)
    }

    // MARK: - Helpers

    private static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: iso) else {
            Issue.record("Failed to parse test date \(iso)")
            return Date.distantPast
        }
        return date
    }
}