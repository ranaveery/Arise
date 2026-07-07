import SwiftUI

struct SkillCardView: View {
    let symbolName: String
    let skillName: String
    let level: Int
    let xp: Int
    let progress: Double
    let gradient: LinearGradient
    let onTap: (() -> Void)?

    private var xpDisplay: String {
        let nextThreshold = level < skillLevelThresholds.count
            ? skillLevelThresholds[level]
            : (skillLevelThresholds.last ?? 0)
        return "\(xp) / \(nextThreshold) XP"
    }

    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) { cardBody }
                .buttonStyle(PlainButtonStyle())
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        HStack(spacing: 14) {
            iconContainer

            VStack(alignment: .leading, spacing: 6) {
                topRow
                progressBar
                xpRow
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private var iconContainer: some View {
        Image(systemName: symbolName)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(gradient)
            .frame(width: 40)
    }

    private var topRow: some View {
        HStack(spacing: 6) {
            Text(skillName)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Text("LVL \(level)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(Color.white.opacity(0.08))
                )
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 5)
                Capsule()
                    .fill(gradient)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)), height: 5)
            }
        }
        .frame(height: 5)
    }

    private var xpRow: some View {
        HStack {
            Text(xpDisplay)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
            Spacer()
        }
    }
}
