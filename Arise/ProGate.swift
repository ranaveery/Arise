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

/// A small gradient "PRO" pill shown next to Pro-owned section titles so users
/// remember a surface is included because they're a paying member.
struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9, weight: .bold))
            Text("PRO")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.5)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(LinearGradient.brand))
        .accessibilityLabel("Arise Pro feature")
    }
}

/// A single thing Arise Pro unlocks. Shared by the Settings card and the paywall
/// so the two can never drift apart.
struct ProPerk: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String?

    /// "Title — detail" form used by the paywall's single-line rows.
    var combinedLabel: String {
        guard let detail else { return title }
        return "\(title) — \(detail)"
    }
}

enum ProPerks {
    static let list: [ProPerk] = [
        ProPerk(id: "insights", icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Insights Pack",
                detail: "momentum, consistency & best month"),
        ProPerk(id: "history", icon: "calendar",
                title: "1-Year & All-Time history",
                detail: nil),
        ProPerk(id: "tasks", icon: "square.and.pencil",
                title: "Custom Tasks",
                detail: "build your own habits"),
        ProPerk(id: "reminders", icon: "bell.badge",
                title: "Custom Reminders",
                detail: "set your own times"),
        ProPerk(id: "export", icon: "square.and.arrow.up",
                title: "Export your data as JSON",
                detail: nil),
        ProPerk(id: "widget", icon: "apps.iphone",
                title: "Home Screen widget",
                detail: "with your streak"),
        ProPerk(id: "onetime", icon: "bag.fill",
                title: "One-time purchase",
                detail: "no subscription"),
    ]
}

/// The grand, visually distinct Arise Pro card used in Settings. Free users see
/// the perk list inline with an upgrade call-to-action; paying users see a
/// compact card that reveals those same perks on tap.
struct AriseProCard: View {
    let isPro: Bool

    @State private var showPaywall = false
    @State private var showPerks = false

    private let glow = Color(red: 84/255, green: 0/255, blue: 232/255)

    var body: some View {
        Button {
            if isPro {
                showPerks = true
            } else {
                showPaywall = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                header
                if !isPro {
                    ProPerksList(checked: false)
                    callToAction
                }
            }
            .padding(isPro ? 16 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LinearGradient.brand, lineWidth: 1.5)
            )
            .shadow(color: glow.opacity(0.5), radius: 22, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isPro ? "Arise Pro. Active." : "Arise Pro. Learn more.")
        .accessibilityHint(isPro ? "Shows everything included with Arise Pro"
                                 : "Opens the Arise Pro upgrade")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showPerks) {
            ProPerksSheet()
        }
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 84/255, green: 0/255, blue: 232/255),
                    Color(red: 236/255, green: 71/255, blue: 1/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.55)
            Color.black.opacity(0.42)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(red: 1, green: 0.9, blue: 0.5)],
                                                    startPoint: .top, endPoint: .bottom))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Arise Pro")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(isPro ? "All Pro features unlocked."
                           : "Unlock the full Arise experience.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Text(isPro ? "Active" : "Learn more")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.18)))

            if isPro {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    private var callToAction: some View {
        Text("Unlock Arise Pro")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Capsule().fill(Color.black.opacity(0.35)))
            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Shared Pro perk list

/// A single row of the Arise Pro perk list. `checked` swaps the trailing lock
/// for a green checkmark (i.e. the viewer already owns Pro).
struct ProPerkRow: View {
    let perk: ProPerk
    let checked: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: perk.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(perk.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                if let detail = perk.detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                }
            }

            Spacer(minLength: 4)

            Image(systemName: checked ? "checkmark.circle.fill" : "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(checked ? Color(red: 0.35, green: 0.9, blue: 0.55) : .white.opacity(0.4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(perk.title)\(perk.detail.map { ", \($0)" } ?? "")")
        .accessibilityValue(checked ? "Included" : "Locked")
    }
}

/// The full list of Pro perks in a rounded card.
struct ProPerksList: View {
    var checked: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(ProPerks.list.enumerated()), id: \.element.id) { index, perk in
                ProPerkRow(perk: perk, checked: checked)
                if index != ProPerks.list.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.12))
                        .padding(.leading, 32)
                }
            }
        }
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Owner's "what you get" sheet

/// Presented when an owner taps the compact Arise Pro card in Settings: a
/// celebratory list of everything they've unlocked.
struct ProPerksSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let glow = Color(red: 84/255, green: 0/255, blue: 232/255)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        heroCard
                        ProPerksList(checked: true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Arise Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 56, height: 56)
                Image(systemName: "crown.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(red: 1, green: 0.9, blue: 0.5)],
                                                    startPoint: .top, endPoint: .bottom))
            }

            Text("You're a Pro")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Text("Everything below is unlocked for good. Thank you for supporting Arise.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("One-time purchase · No subscription")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.18)))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LinearGradient.brand, lineWidth: 1.5)
        )
        .shadow(color: glow.opacity(0.5), radius: 22, x: 0, y: 10)
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 84/255, green: 0/255, blue: 232/255),
                    Color(red: 236/255, green: 71/255, blue: 1/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.55)
            Color.black.opacity(0.42)
        }
    }
}
