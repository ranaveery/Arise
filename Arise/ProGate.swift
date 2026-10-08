//
//  ProGate.swift
//  Arise
//
//  Small reusable UI for Pro-gated features. Each row owns its own paywall
//  sheet so call sites stay tiny and behave consistently.
//

import SwiftUI

/// A settings-style row that represents a locked (Pro-only) feature. Tapping it
/// presents the Arise Pro paywall.
struct LockedFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var showsChevron: Bool = true

    @State private var showPaywall = false

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.45))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Pro")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LinearGradient.brand))

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .accessibilityLabel("\(title). Arise Pro feature.")
        .accessibilityHint("Opens the Arise Pro upgrade")
    }
}

/// A centered locked card used inside content areas (e.g. Trends insights).
struct LockedProCard: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String = "Unlock with Arise Pro"

    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(LinearGradient.brand)
                .padding(.top, 6)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showPaywall = true
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(LinearGradient.brand))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .accessibilityHint("Opens the Arise Pro upgrade")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// Shared section title styling used by Pro feature surfaces.
struct ProSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}