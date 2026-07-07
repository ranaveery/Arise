import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SkillDetailPopup: View {
    let symbolName: String
    let skillName: String
    let skillXP: Int
    let skillLevel: Int
    let themeColors: [Color]

    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var animatedProgress: Double = 0
    @State private var todaySkillXP: [String: Int] = [:]
    @State private var todayTaskContributions: [[String: Any]] = []
    @State private var showContent = false

    private var currentThreshold: Int {
        skillLevelThresholds[safe: skillLevel - 1] ?? 0
    }
    private var nextThreshold: Int {
        skillLevelThresholds[safe: skillLevel] ?? skillLevelThresholds.last ?? 0
    }
    private var progressToNext: Double {
        let range = Double(nextThreshold - currentThreshold)
        guard range > 0 else { return 1.0 }
        return min(max((Double(skillXP) - Double(currentThreshold)) / range, 0), 1.0)
    }

    private var todayXPForSkill: Int {
        todaySkillXP[skillName] ?? 0
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    emblemHeader
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    progressRingSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    if todayXPForSkill > 0 {
                        todayContributionSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                    }

                    levelThresholdsSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
        }
        .presentationCornerRadius(30)
        .onAppear {
            fetchTodayData()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { showContent = true }
            if animationsEnabled {
                withAnimation(.easeOut(duration: 1.2).delay(0.3)) { animatedProgress = progressToNext }
            } else {
                animatedProgress = progressToNext
            }
        }
    }

    // MARK: - Emblem header
    private var emblemHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: themeColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                Image(systemName: symbolName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: (themeColors.first ?? .purple).opacity(0.4), radius: 12, y: 4)

            Text(skillName)
                .font(.title.bold())
                .foregroundStyle(
                    LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                )

            HStack(spacing: 8) {
                levelBadge
                Text("•")
                    .foregroundColor(.white.opacity(0.3))
                Text("\(skillXP) XP")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var levelBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text("Level \(skillLevel)")
                .font(.subheadline.weight(.bold))
        }
        .foregroundColor(themeColors.first ?? .purple)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background((themeColors.first ?? .purple).opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Progress ring
    private var progressRingSection: some View {
        VStack(spacing: 8) {
            ZStack {
                ProgressRing(
                    progress: animatedProgress,
                    gradient: LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing),
                    size: 120
                )

                VStack(spacing: 2) {
                    Text("\(Int(progressToNext * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("to next")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            if skillLevel < skillLevelThresholds.count {
                Text("\(skillXP - currentThreshold) / \(nextThreshold - currentThreshold) XP")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
            } else {
                Text("Max Level Reached")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                    )
            }
        }
    }

    // MARK: - Today's contribution
    private var todayContributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel("Today's Contribution")

            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing))
                Text("+\(todayXPForSkill) XP to \(skillName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 4)

            ForEach(todayTaskContributions.indices, id: \.self) { i in
                let entry = todayTaskContributions[i]
                if let skillXP = entry["skillXP"] as? [String: Int],
                   let add = skillXP[skillName],
                   let name = entry["name"] as? String {
                    HStack(spacing: 8) {
                        Circle()
                            .fill((themeColors.first ?? .purple).opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(name)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text("+\(add) XP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                            )
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Level thresholds
    private var levelThresholdsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel("Level Thresholds")

            VStack(spacing: 6) {
                ForEach(1...skillLevelThresholds.count, id: \.self) { level in
                    let lower = skillLevelThresholds[level - 1]
                    let upper = level < skillLevelThresholds.count
                        ? skillLevelThresholds[level] - 1
                        : skillLevelThresholds.last ?? lower
                    let isCurrent = level == skillLevel

                    levelRow(level: level, lower: lower, upper: upper, isCurrent: isCurrent)
                }
            }
        }
    }

    private func levelRow(level: Int, lower: Int, upper: Int, isCurrent: Bool) -> some View {
        HStack {
            HStack(spacing: 8) {
                if isCurrent {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing))
                }
                Text("Level \(level)")
                    .fontWeight(isCurrent ? .bold : .regular)
                    .foregroundColor(isCurrent ? (themeColors.first ?? .white) : .white.opacity(0.7))
            }

            Spacer()

            Text("\(lower) – \(upper) XP")
                .font(.caption)
                .foregroundColor(.white.opacity(isCurrent ? 0.9 : 0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCurrent
                                ? LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isCurrent ? 1.2 : 0
                        )
                )
        )
        .shadow(color: isCurrent ? (themeColors.first?.opacity(0.2) ?? .purple.opacity(0.2)) : .clear, radius: 4, y: 2)
    }

    private func sectionHeaderLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing))
                .frame(width: 2, height: 14)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
        }
    }

    // MARK: - Firestore fetch
    private func fetchTodayData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            todaySkillXP = data["todaySkillXP"] as? [String: Int] ?? [:]
            if let details = data["todayCompletedTaskDetails"] as? [[String: Any]] {
                todayTaskContributions = details.filter { entry in
                    guard let skillXP = entry["skillXP"] as? [String: Int] else { return false }
                    return skillXP.keys.contains(skillName)
                }
            }
        }
    }
}

