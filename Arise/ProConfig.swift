//
//  ProConfig.swift
//  Arise
//
//  Constants for the Arise Pro one-time unlock and grandfathering.
//

import Foundation

enum ProConfig {
    /// The single StoreKit product ID for Arise Pro (one-time, non-consumable).
    /// This value cannot be changed after the product is created in App Store Connect.
    static let productID = "com.ranaveer.Arise.pro"

    // MARK: Paid era window (grandfathering)

    // Paid era window (UTC). First $3 sale was July 15, 2026; buffer -2 days =
    // July 13. Paid era ends the day v2.1.0 (free + IAP) goes live: Dec 1, 2026.
    static let paidEraStart: Date? = Self.date(year: 2026, month: 7, day: 13)
    static let paidEraEnd: Date? = Self.date(year: 2026, month: 12, day: 1)

    /// Builds a UTC midnight date so the window matches App Store timestamps
    /// (which are also UTC).
    private static func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date
    }

    /// Grandfathering rule: everyone who first received the app inside the paid
    /// era window (`paidEraStart` inclusive, `paidEraEnd` exclusive) gets Arise
    /// Pro automatically and permanently. Anyone who installed before the paid
    /// era, or on/after the free release, is not grandfathered (they keep every
    /// feature the app has today; Pro is an optional upgrade for them).
    static var grandfatherDatesAreConfigured: Bool {
        paidEraStart != nil && paidEraEnd != nil
    }

    /// Pure grandfathering rule. Returns `true` when the original purchase date
    /// falls inside the paid era window: `start <= date < end`.
    /// Returns `false` if the window is not configured or inverted.
    static func isGrandfathered(
        paidEraStart: Date?,
        paidEraEnd: Date?,
        originalPurchaseDate: Date
    ) -> Bool {
        guard let start = paidEraStart, let end = paidEraEnd, start < end else {
            return false
        }
        return originalPurchaseDate >= start && originalPurchaseDate < end
    }

    /// Convenience overload using the configured window.
    static func isGrandfathered(originalPurchaseDate: Date) -> Bool {
        isGrandfathered(
            paidEraStart: paidEraStart,
            paidEraEnd: paidEraEnd,
            originalPurchaseDate: originalPurchaseDate
        )
    }
}
