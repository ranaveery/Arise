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

    // TODO(set-me): First day of the paid era, one or two days BEFORE the first
    // $3 sale. Check App Store Connect > Trends > Sales, filter Arise, May to now,
    // and use the date of the first sale minus 1-2 days (UTC).
    static let paidEraStart: Date? = nil

    // TODO(set-me): The day the free + in-app-purchase update goes live (UTC).
    // Never default this to the distant future - that would give Pro to every
    // new free user. Must be later than `paidEraStart`.
    static let paidEraEnd: Date? = nil

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
