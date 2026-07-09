import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {

    @State private var totalXP: Int = 0
    @State private var skillData: [String: [String: Int]] = [:]
    @State private var isLoading = true
    @State private var userName: String = ""
    @State private var streak: Int = 0
    @State private var glowPulse = false
    @State private var selectedSkill: IdentifiedString? = nil
    @State private var greeting: String = ""
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var listener: ListenerRegistration?
    @AppStorage("lastRankId") private var lastRankId: Int = 0
    @State private var isFirstSnapshot = true

    private let greetings = [
        "Make it count.", "You're doing great.", "One day at a time.",
        "Small steps, big wins.", "Stay consistent.", "You've got this.",
        "Progress over perfection.", "Show up for yourself.",
        "Every action matters.", "Keep showing up.", "Rise and grind.",
        "Better than yesterday.", "Your future self will thank you.",
        "Champions are made in practice.", "Trust the process.",
        "Be 1% better today.", "The best time is now.",
        "Discipline > Motivation", "Don't break the chain.", "Every rep counts."
    ]

    private var currentRank: Rank {
        ranks.last(where: { Double(totalXP) >= $0.requiredXP }) ?? ranks[0]
    }
    private var nextRank: Rank {
        ranks.first(where: { $0.requiredXP > Double(totalXP) }) ?? currentRank
    }
    private var rankGradient: LinearGradient {
        LinearGradient(colors: currentRank.themeColors, startPoint: .leading, endPoint: .trailing)
    }
    private var xpProgress: Double {
        let prevXP = currentRank.requiredXP
        let nextXP = nextRank.requiredXP
        guard nextXP > prevXP else { return 1 }
        return min(max((Double(totalXP) - prevXP) / (nextXP - prevXP), 0), 1)
    }
    private var xpDisplay: String {
        let formattedTotal = totalXP.formatted(.number.grouping(.automatic))
        if currentRank.id == ranks.last?.id {
            return "\(formattedTotal) / \(Int(currentRank.requiredXP).formatted(.number.grouping(.automatic))) XP"
        } else {
            return "\(formattedTotal) / \(Int(nextRank.requiredXP).formatted(.number.grouping(.automatic))) XP"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            greetingRow
                            rankHeader
                            skillCardsSection
                            Spacer(minLength: 40)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await refreshUserData()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                greeting = greetings.randomElement() ?? ""
                glowPulse = true
                fetchUserData()
            }
            .onDisappear {
                listener?.remove()
            }
            .sheet(item: $selectedSkill) { item in
                let name = item.value
                SkillDetailPopup(
                    symbolName:  skillIcons[name] ?? "questionmark.circle",
                    skillName:   name,
                    skillXP:     skillData[name]?["xp"]    ?? 0,
                    skillLevel:  skillData[name]?["level"] ?? 1,
                    themeColors: currentRank.themeColors
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Greeting Row

    private var greetingRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back, \(userName)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(greeting)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .italic()
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.orange, .orange.opacity(0.9))
                    .font(.system(size: 20))
                    .shadow(color: .orange.opacity(0.5), radius: 4, y: 0)
                Text("\(streak)")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Rank Header

    private var rankHeader: some View {
        NavigationLink(destination: RankDetailsView()) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(rankGradient)
                            .frame(width: 90, height: 90)
                            .scaleEffect(glowPulse && animationsEnabled ? 1 : 0.85)
                            .opacity(glowPulse && animationsEnabled ? 0.45 : 0.3)
                            .blur(radius: 26)
                            .animation(
                                animationsEnabled
                                    ? .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
                                    : nil,
                                value: glowPulse
                            )

                        Image(currentRank.emblemName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentRank.name.uppercased())
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(rankGradient)

                        Text(currentRank.subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.38))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                }

                VStack(spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 7)
                            Capsule()
                                .fill(rankGradient)
                                .frame(width: geo.size.width * CGFloat(xpProgress), height: 7)
                                .animation(
                                    animationsEnabled ? .easeOut(duration: 0.7) : nil,
                                    value: xpProgress
                                )
                        }
                    }
                    .frame(height: 7)

                    HStack {
                        Text(xpDisplay)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        if currentRank.id != ranks.last?.id {
                            Text("→ \(nextRank.name)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityHint("Tap to view rank details and achievements")
    }

    // MARK: - Skill Cards

    private var skillCardsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Skills")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("Tap a skill for details")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.35))
            }

            ForEach(sortedSkills, id: \.key) { skill, icon in
                let level    = skillData[skill]?["level"] ?? 1
                let xp       = skillData[skill]?["xp"]    ?? 0
                let progress = skillProgress(for: xp)

                SkillCardView(
                    symbolName:  icon,
                    skillName:   skill,
                    level:       level,
                    xp:          xp,
                    progress:    progress,
                    gradient:    rankGradient,
                    onTap: { selectedSkill = IdentifiedString(skill) }
                )
            }
        }
    }

    private var sortedSkills: [(key: String, value: String)] {
        skillIcons.sorted { $0.key < $1.key }
    }

    // MARK: - Data

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        let docRef = Firestore.firestore().collection("users").document(uid)

        listener = docRef.addSnapshotListener { snapshot, error in
            if error != nil { return }
            guard let data = snapshot?.data() else { return }

            let newTotalXP = data["xp"] as? Int ?? 0
            let newSkillData = data["skills"] as? [String: [String: Int]] ?? [:]
            let newName = data["name"] as? String ?? "User"
            let newStreak = data["streak"] as? Int ?? 0
            let firestoreRank = data["rank"] as? String ?? "Seeker"

            var updatedSkillData: [String: [String: Int]] = [:]
            for (skill, values) in newSkillData {
                let xp = values["xp"] ?? 0
                let level = calculateSkillLevel(from: xp)
                updatedSkillData[skill] = ["xp": xp, "level": level]
            }

            let computedRankName = ranks.last(where: { Double(newTotalXP) >= $0.requiredXP })?.name ?? "Seeker"
            let computedRank = ranks.last(where: { Double(newTotalXP) >= $0.requiredXP }) ?? ranks[0]

            lastRankId = computedRank.id
            isFirstSnapshot = false

            self.totalXP = newTotalXP
            self.skillData = updatedSkillData
            self.userName = newName
            self.streak = newStreak
            self.isLoading = false

            if firestoreRank != computedRankName {
                self.syncRank(computedRankName, uid: uid)
            }

            let safeData = safeForUserDefaults(data)
            UserDefaults.standard.set(safeData, forKey: "cachedUserData")
        }
    }

    private func refreshUserData() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard let data = snapshot.data() else { return }

            await MainActor.run {
                self.totalXP = data["xp"] as? Int ?? 0
                self.userName = data["name"] as? String ?? "User"
                self.streak = data["streak"] as? Int ?? 0

                let newSkillData = data["skills"] as? [String: [String: Int]] ?? [:]
                var updatedSkillData: [String: [String: Int]] = [:]
                for (skill, values) in newSkillData {
                    let xp = values["xp"] ?? 0
                    let level = calculateSkillLevel(from: xp)
                    updatedSkillData[skill] = ["xp": xp, "level": level]
                }
                self.skillData = updatedSkillData

                let firestoreRank = data["rank"] as? String ?? "Seeker"
                let computedRankName = ranks.last(where: { Double(self.totalXP) >= $0.requiredXP })?.name ?? "Seeker"
                if firestoreRank != computedRankName {
                    self.syncRank(computedRankName, uid: uid)
                }
            }
        } catch { }
    }

    private func syncRank(_ rankName: String, uid: String) {
        Firestore.firestore().collection("users").document(uid)
            .updateData(["rank": rankName])
    }

    private func safeForUserDefaults(_ dict: [String: Any]) -> [String: Any] {
        var safe = [String: Any]()
        for (key, value) in dict {
            if let ts = value as? Timestamp {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                safe[key] = formatter.string(from: ts.dateValue())
            } else if let subDict = value as? [String: Any] {
                safe[key] = safeForUserDefaults(subDict)
            } else {
                safe[key] = value
            }
        }
        return safe
    }
}
