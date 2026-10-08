//
//  PaywallView.swift
//  Arise
//
//  The Arise Pro one-time purchase sheet. Driven entirely by ProStore:
//  - loading / product failed to load (retry)
//  - ready (price from product.displayPrice)
//  - purchasing / pending / failed
//  - owned (purchased or grandfathered) — "You already own Arise Pro"
//
//  No hard-coded prices: the only price comes from Product.displayPrice.
//  In DEBUG builds a toolbar menu can preview every state (the StoreKit
//  configuration arrives in Phase 4, so the live store has no product yet).
//

import SwiftUI

private enum PaywallDisplayState: Equatable {
    case loading
    case productFailed(message: String)
    case ready(price: String)
    case purchasing(price: String)
    case pending(String)
    case failed(String)
    case owned
}

#if DEBUG
enum PaywallDebugOverride: String, CaseIterable, Identifiable {
    case loading
    case productFailed
    case ready
    case purchasing
    case pending
    case failed
    case owned

    var id: String { rawValue }

    var label: String {
        switch self {
        case .loading: return "Loading"
        case .productFailed: return "Product failed"
        case .ready: return "Ready"
        case .purchasing: return "Purchasing"
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .owned: return "Owned"
        }
    }
}
#endif

struct PaywallView: View {
    @Environment(ProStore.self) private var proStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    #if DEBUG
    @State private var debugOverride: PaywallDebugOverride?
    #endif

    private static let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyURL = URL(string: "https://ranaveery.github.io/Arise/")!

    private var isOwned: Bool { proStore.isPro }

    private var displayState: PaywallDisplayState {
        #if DEBUG
        if let override = debugOverride {
            switch override {
            case .loading:
                return .loading
            case .productFailed:
                return .productFailed(message: proStore.productLoadError ?? "Couldn't load Arise Pro. Check your connection and try again.")
            case .ready:
                return .ready(price: proStore.product?.displayPrice ?? "(price)")
            case .purchasing:
                return .purchasing(price: proStore.product?.displayPrice ?? "(price)")
            case .pending:
                return .pending("Your purchase is waiting for approval. You'll get Arise Pro as soon as it's approved.")
            case .failed:
                return .failed("Purchase failed. Please try again.")
            case .owned:
                return .owned
            }
        }
        #endif

        if isOwned { return .owned }

        switch proStore.purchaseState {
        case .purchasing:
            return .purchasing(price: proStore.product?.displayPrice ?? "")
        case .pending(let message):
            return .pending(message)
        case .failed(let message):
            return .failed(message)
        case .idle:
            break
        }

        if proStore.status == .loading || proStore.isLoadingProduct {
            return .loading
        }
        if let product = proStore.product {
            return .ready(price: product.displayPrice)
        }
        return .productFailed(
            message: proStore.productLoadError ?? "Couldn't load Arise Pro. Check your connection and try again."
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    heroHeader
                    contentView
                    if !isOwned {
                        restoreButton
                    }
                    legalLinks
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.35))
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Dismisses Arise Pro")

            Spacer()

            #if DEBUG
            Menu {
                Button("Auto (live store)") { debugOverride = nil }
                Divider()
                ForEach(PaywallDebugOverride.allCases) { state in
                    Button(state.label) { debugOverride = state }
                }
            } label: {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.45))
            }
            .accessibilityLabel("Preview paywall state")
            .accessibilityHint("Debug-only preview of each state")
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Header

    private var heroHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                     Color(red: 236/255, green: 71/255, blue: 1/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Arise Pro")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Text("One-time purchase. Every feature, forever.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch displayState {
        case .loading:
            loadingView
        case .productFailed(let message):
            productFailedView(message: message)
        case .ready(let price):
            purchaseView(price: price, isPurchasing: false, inlineMessage: nil)
        case .purchasing(let price):
            purchaseView(price: price, isPurchasing: true, inlineMessage: nil)
        case .pending(let message):
            purchaseView(price: proStore.product?.displayPrice ?? "", isPurchasing: true, inlineMessage: message)
        case .failed(let message):
            purchaseView(price: proStore.product?.displayPrice ?? "", isPurchasing: false, inlineMessage: message)
        case .owned:
            ownedView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .accessibilityLabel("Loading Arise Pro")
            Text("Loading Arise Pro…")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func productFailedView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 42))
                .foregroundColor(.white.opacity(0.4))
                .accessibilityHidden(true)

            Text("Arise Pro couldn't load right now.")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                Task { await proStore.retryLoadProduct() }
            } label: {
                Text("Retry")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                     Color(red: 236/255, green: 71/255, blue: 1/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Retry loading Arise Pro")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func purchaseView(price: String, isPurchasing: Bool, inlineMessage: String?) -> some View {
        VStack(spacing: 20) {
            featureList

            if let message = inlineMessage {
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                Task { await proStore.purchase() }
            } label: {
                HStack(spacing: 10) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isPurchasing ? "Purchasing…" : "Unlock Arise Pro \(price.isEmpty ? "" : "· \(price)")")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                 Color(red: 236/255, green: 71/255, blue: 1/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isPurchasing)
            .accessibilityLabel(isPurchasing ? "Purchasing Arise Pro" : "Buy Arise Pro \(price)")
            .accessibilityHint(isPurchasing ? "Purchase in progress" : "Opens the App Store purchase sheet")
        }
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ProPerks.list.enumerated()), id: \.element.id) { index, perk in
                featureRow(icon: perk.icon, text: perk.combinedLabel)
                if index != ProPerks.list.count - 1 {
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .frame(width: 24)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    private var ownedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                 Color(red: 236/255, green: 71/255, blue: 1/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text("You already own Arise Pro.")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Text("Thank you for supporting Arise from the start.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Done")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Restore & legal

    private var restoreButton: some View {
        Button {
            Task { await proStore.restore() }
        } label: {
            Text("Restore Purchases")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 6)
        .accessibilityLabel("Restore purchases")
        .accessibilityHint("Checks the App Store for purchases you already made")
    }

    private var legalLinks: some View {
        HStack(spacing: 18) {
            Button {
                UIApplication.shared.open(Self.eulaURL)
            } label: {
                Text("Terms of Use")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .underline()
            }
            .accessibilityLabel("Terms of Use")

            Button {
                UIApplication.shared.open(Self.privacyURL)
            } label: {
                Text("Privacy Policy")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .underline()
            }
            .accessibilityLabel("Privacy Policy")
        }
        .padding(.top, 4)
    }
}