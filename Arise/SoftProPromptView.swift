//
//  SoftProPromptView.swift
//  Arise
//
//  A gentle, dismissible card that invites the user to learn about Arise Pro.
//  It appears only after a rank-up celebration is dismissed (see
//  MainTabView), respects ProPromptTracker's throttling, and never interrupts
//  a quest. Tapping "Learn more" opens the full PaywallView sheet.
//

import SwiftUI

struct SoftProPromptView: View {
    let onLearnMore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 40, height: 40)
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Unlock Arise Pro")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                Text("One-time purchase. Every feature, forever.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer(minLength: 8)

            Button("Not now") { onDismiss() }
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(.white.opacity(0.45))
                .accessibilityLabel("Not now")
                .accessibilityHint("Dismisses this suggestion")

            Button("Learn more") { onLearnMore() }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                 Color(red: 236/255, green: 71/255, blue: 1/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .accessibilityLabel("Learn more about Arise Pro")
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .contain)
    }
}