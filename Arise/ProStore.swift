//
//  ProStore.swift
//  Arise
//
//  Single source of truth for the Arise Pro entitlement (StoreKit 2).
//  StoreKit is the only source of truth for purchases; grandfathering is
//  derived from the app's original purchase date via AppTransaction.
//

import Foundation
import Observation
import StoreKit
import UIKit

// MARK: - Status

enum ProStatus: String {
    case loading
    case free
    case purchased
    case grandfathered

    var isPro: Bool {
        self == .purchased || self == .grandfathered
    }
}

enum ProPurchaseState: Equatable {
    case idle
    case purchasing
    case pending(String)
    case failed(String)
}

// MARK: - Purchase history (injection point for tests)

enum ProStoreError: Error {
    case appTransactionUnavailable
}

protocol PurchaseHistoryProviding {
    /// Returns the app's original purchase date when the App Transaction is
    /// verified. Throws when it cannot be fetched or verified.
    func verifiedOriginalPurchaseDate() async throws -> Date
}

struct AppTransactionPurchaseHistory: PurchaseHistoryProviding {
    func verifiedOriginalPurchaseDate() async throws -> Date {
        // AppTransaction.shared may be a VerificationResult depending on the
        // SDK; only a .verified transaction is trusted.
        let result = try await AppTransaction.shared
        guard case .verified(let transaction) = result else {
            throw ProStoreError.appTransactionUnavailable
        }
        return transaction.originalPurchaseDate
    }
}

// MARK: - Debug override (DEBUG builds only)

#if DEBUG
enum ProDebugOverride: String, CaseIterable {
    case free
    case purchased
    case grandfathered

    static let defaultsKey = "proDebugOverride"

    static var current: ProDebugOverride? {
        guard let raw = UserDefaults.standard.string(forKey: defaultsKey) else { return nil }
        return ProDebugOverride(rawValue: raw)
    }

    var proStatus: ProStatus {
        switch self {
        case .free: return .free
        case .purchased: return .purchased
        case .grandfathered: return .grandfathered
        }
    }

    var label: String {
        switch self {
        case .free: return "Free"
        case .purchased: return "Purchased"
        case .grandfathered: return "Grandfathered"
        }
    }
}
#endif

// MARK: - ProStore

@MainActor
@Observable
final class ProStore {

    private(set) var status: ProStatus
    private(set) var product: Product?
    private(set) var purchaseState: ProPurchaseState = .idle
    private(set) var productLoadError: String?
    private(set) var isLoadingProduct = false

    var isPro: Bool { status.isPro }

    private let purchaseHistory: PurchaseHistoryProviding
    private var updatesTask: Task<Void, Never>?
    private var didBecomeActiveObserver: NSObjectProtocol?

    private enum Keys {
        static let cachedStatus = "proCachedStatus"
        static let grandfatheredVerified = "proGrandfatheredVerified"
    }

    init(purchaseHistory: PurchaseHistoryProviding = AppTransactionPurchaseHistory()) {
        self.purchaseHistory = purchaseHistory
        self.status = Self.restoredStatus()
    }

    // MARK: Lifecycle

    /// Starts the transaction listener and the initial, non-blocking refresh.
    /// Safe to call more than once.
    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                guard let self else { return }
                for await update in Transaction.updates {
                    await self.handle(update)
                }
            }
        }
        if didBecomeActiveObserver == nil {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshEntitlements()
                }
            }
        }
        Task {
            await refreshEntitlements()
            await loadProduct()
        }
    }

    // MARK: Product

    func loadProduct() async {
        isLoadingProduct = true
        productLoadError = nil

        var lastAttemptFailed = false
        for attempt in 1...3 {
            do {
                let products = try await Product.products(for: [ProConfig.productID])
                if let loaded = products.first {
                    product = loaded
                    isLoadingProduct = false
                    return
                }
                lastAttemptFailed = true
            } catch {
                lastAttemptFailed = true
            }
            if attempt < 3 {
                try? await Task.sleep(for: .seconds(Double(attempt) * 0.75))
            }
        }

        isLoadingProduct = false
        if lastAttemptFailed {
            productLoadError = "Couldn't load Arise Pro. Check your connection and try again."
        }
    }

    func retryLoadProduct() async {
        await loadProduct()
    }

    // MARK: Purchase

    func purchase() async {
        guard let product else {
            purchaseState = .failed("Arise Pro isn't available right now. Please try again.")
            await loadProduct()
            return
        }

        purchaseState = .purchasing
        do {
            switch try await product.purchase() {
            case .success(let result):
                switch result {
                case .verified(let transaction):
                    await refreshEntitlements()
                    await transaction.finish()
                    purchaseState = isPro ? .idle : .failed("Purchase could not be verified.")
                case .unverified:
                    // Never grant on an unverified transaction; clear it so it
                    // is not redelivered forever.
                    purchaseState = .failed("Purchase could not be verified.")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .pending("Your purchase is waiting for approval. You'll get Arise Pro as soon as it's approved.")
            @unknown default:
                purchaseState = .idle
            }
        } catch is CancellationError {
            purchaseState = .idle
        } catch {
            purchaseState = .failed(Self.friendlyMessage(for: error))
        }
    }

    // MARK: Restore

    func restore() async {
        purchaseState = .purchasing
        var syncFailed = false
        do {
            try await AppStore.sync()
        } catch {
            syncFailed = true
        }
        await refreshEntitlements()
        if isPro {
            purchaseState = .idle
        } else {
            purchaseState = .failed(
                syncFailed
                    ? "Restore was cancelled."
                    : "No previous purchases were found."
            )
        }
    }

    // MARK: Entitlements

    /// Re-verifies the entitlement: verified StoreKit transactions first,
    /// then grandfathering. Always re-run on launch and on foreground.
    func refreshEntitlements() async {
        #if DEBUG
        if let override = ProDebugOverride.current {
            status = override.proStatus
            return
        }
        #endif

        var hasVerifiedPurchase = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == ProConfig.productID else { continue }
            if transaction.revocationDate == nil {
                hasVerifiedPurchase = true
                break
            }
        }

        if hasVerifiedPurchase {
            status = .purchased
            cache(status)
            return
        }

        await resolveGrandfatherStatus()
    }

    private func resolveGrandfatherStatus() async {
        // A verified-grandfathered result is cached permanently and always wins.
        if UserDefaults.standard.bool(forKey: Keys.grandfatheredVerified) {
            status = .grandfathered
            cache(status)
            return
        }

        do {
            let purchaseDate = try await purchaseHistory.verifiedOriginalPurchaseDate()
            if ProConfig.isGrandfathered(originalPurchaseDate: purchaseDate) {
                UserDefaults.standard.set(true, forKey: Keys.grandfatheredVerified)
                status = .grandfathered
            } else {
                // Verified, but outside the paid era (or the window is not yet
                // configured) - fail closed.
                status = .free
            }
            cache(status)
        } catch {
            // Fail closed: verification threw and there is no cached result.
            // Retry happens on the next launch and on foreground.
            status = .free
            cache(status)
        }
    }

    // MARK: Transaction updates

    private func handle(_ result: VerificationResult<Transaction>) async {
        let transaction = result.unsafePayloadValue

        guard transaction.productID == ProConfig.productID else {
            if case .verified = result { await transaction.finish() }
            return
        }

        guard case .verified(let verified) = result else {
            // Unverified: never grant. Finish it so it is not redelivered.
            await transaction.finish()
            return
        }

        if verified.revocationDate == nil {
            status = .purchased
            cache(status)
        } else {
            // Refund / revocation: fall back to grandfathering or free.
            // The user's app data is never touched.
            await resolveGrandfatherStatus()
        }
        await transaction.finish()
    }

    // MARK: Caching

    private static func restoredStatus() -> ProStatus {
        guard let raw = UserDefaults.standard.string(forKey: Keys.cachedStatus),
              let cached = ProStatus(rawValue: raw),
              cached != .loading else {
            return .loading
        }
        return cached
    }

    private func cache(_ value: ProStatus) {
        guard value != .loading else { return }
        UserDefaults.standard.set(value.rawValue, forKey: Keys.cachedStatus)
    }

    // MARK: Debug override (DEBUG builds only)

    #if DEBUG
    func setDebugOverride(_ override: ProDebugOverride?) {
        UserDefaults.standard.set(override?.rawValue, forKey: ProDebugOverride.defaultsKey)
        if let override {
            status = override.proStatus
        } else {
            status = Self.restoredStatus()
            Task { await refreshEntitlements() }
        }
    }
    #endif

    // MARK: Helpers

    private static func friendlyMessage(for error: Error) -> String {
        if let purchaseError = error as? Product.PurchaseError {
            switch purchaseError {
            case .productUnavailable:
                return "Arise Pro isn't available right now. Please try again later."
            case .purchaseNotAllowed:
                return "In-app purchases are not allowed on this device."
            default:
                break
            }
        }
        return "Purchase failed. Please try again."
    }
}
