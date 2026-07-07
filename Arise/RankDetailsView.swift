import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RankDetailsView: View {
    @State private var currentXP: Double = 0
    @State private var currentRankId: Int = 1
    @State private var showRankPopup = false
    @State private var skillXPs: [SkillXP] = [
        SkillXP(name: "Discipline", level: 1, xp: 0),
        SkillXP(name: "Fitness", level: 1, xp: 0),
        SkillXP(name: "Fuel", level: 1, xp: 0),
        SkillXP(name: "Network", level: 1, xp: 0),
        SkillXP(name: "Resilience", level: 1, xp: 0),
        SkillXP(name: "Wisdom", level: 1, xp: 0)
    ]

    @State private var animatedSkillProgress: [String: Double] = [:]
    @State private var listener: ListenerRegistration?
    
    @State private var achievements: [Achievement] = [
        
        Achievement(index: 1,
                    title: "The Journey Begins",
                    imageName: "a1_image",
                    description: "Reach Initiate.",
                    quote: "Every master was once an initiate."),

        Achievement(index: 2,
                    title: "Trailblazer",
                    imageName: "a2_image",
                    description: "Reach Pioneer.",
                    quote: "Those who dare, lead the way."),

        Achievement(index: 3,
                    title: "World Explorer",
                    imageName: "a3_image",
                    description: "Reach Explorer.",
                    quote: "Adventure begins where comfort ends."),

        Achievement(index: 4,
                    title: "Against All Odds",
                    imageName: "a4_image",
                    description: "Reach Challenger.",
                    quote: "Greatness is forged in challenges."),

        Achievement(index: 5,
                    title: "The Refiner’s Flame",
                    imageName: "a5_image",
                    description: "Reach Refiner.",
                    quote: "Through refinement, we find destiny — you’re halfway there."),

        Achievement(index: 6,
                    title: "Path to Mastery",
                    imageName: "a6_image",
                    description: "Reach Master.",
                    quote: "Discipline transforms talent into mastery."),

        Achievement(index: 7,
                    title: "The Conqueror",
                    imageName: "a7_image",
                    description: "Reach Conquerer.",
                    quote: "Victory belongs to the relentless."),

        Achievement(index: 8,
                    title: "Beyond Limits",
                    imageName: "a8_image",
                    description: "Reach Ascendant.",
                    quote: "Rise above what you once thought impossible."),

        Achievement(index: 9,
                    title: "Transcendent Being",
                    imageName: "a9_image",
                    description: "Reach Transcendent.",
                    quote: "Transcendence is not the end, but a new beginning."),
        
        Achievement(index: 10,
                    title: "First Steps",
                    imageName: "a10_image",
                    description: "You earned your very first XP!",
                    quote: "Every journey begins with a single step."),
        
        Achievement(index: 11,
                    title: "Flame of Discipline",
                    imageName: "a11_image",
                    description: "Reached level 10 in Discipline.",
                    quote: "Consistency beats intensity."),
        
        Achievement(index: 12,
                    title: "Peak Performer",
                    imageName: "a12_image",
                    description: "Reached Level 10 in Fitness.",
                    quote: "Strength is built one rep at a time."),

        Achievement(index: 13,
                    title: "Fuel of Champions",
                    imageName: "a13_image",
                    description: "Reached Level 10 in Fuel.",
                    quote: "Discipline at the table shapes results in the gym."),

        Achievement(index: 14,
                    title: "Connector of Worlds",
                    imageName: "a14_image",
                    description: "Reached Level 10 in Network.",
                    quote: "Your network is your net worth."),

        Achievement(index: 15,
                    title: "Iron Spirit",
                    imageName: "a15_image",
                    description: "Reached Level 10 in Resilience.",
                    quote: "Fall seven times, stand up eight."),

        Achievement(index: 16,
                    title: "Sage of Growth",
                    imageName: "a16_image",
                    description: "Reached Level 10 in Wisdom.",
                    quote: "Knowledge speaks, wisdom listens."),


    ]
    
    @State private var glowPulse = false
    @State private var selectedAchievement: Achievement? = nil
    
    private var rankGradient: LinearGradient {
        LinearGradient(
            colors: currentRank.themeColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                CurrentRankView(currentRank: currentRank, nextRank: nextRank, currentXP: currentXP, currentXPProgress: currentXPProgress, gradient: rankGradient)
                
                NextRankView(nextRank: nextRank, showPopup: $showRankPopup)
                
                SkillContributionsView(skillXPs: skillXPs, gradient: rankGradient)
                
                AchievementsView(achievements: achievements, selectedAchievement: $selectedAchievement, gradient: rankGradient)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showRankPopup) {
            RankPopupView(ranks: ranks, currentRankId: currentRankId)
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementPopupView(
                achievement: achievement,
                ranks: ranks,
                currentRankId: currentRankId
            )
        }
        .onAppear {
            glowPulse = true
            loadUserData()
        }
        .onDisappear {
            listener?.remove()
        }
    }
    
    // MARK: - Computed Properties
    private var currentRank: Rank {
        ranks.last(where: { Double(currentXP) >= $0.requiredXP }) ?? ranks[0]
    }
    
    private var nextRank: Rank {
        ranks.first(where: { $0.requiredXP > Double(currentXP) }) ?? currentRank
    }
    
    private var currentXPProgress: Double {
        let prevXP = currentRank.requiredXP
        let nextXP = nextRank.requiredXP
        guard nextXP > prevXP else { return 1 } // max rank
        let progress = (currentXP - prevXP) / (nextXP - prevXP)
        return min(max(progress, 0), 1)
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        listener = Firestore.firestore().collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            
            currentXP = Double(data["xp"] as? Int ?? 0)
            
            if let rankName = data["rank"] as? String,
               let rank = ranks.first(where: { $0.name == rankName }) {
                currentRankId = rank.id
            }
            
            if let achievementsData = data["achievements"] as? [String: [String: Any]] {
                achievements = achievements.map { achievement in
                    if let achData = achievementsData["\(achievement.index)"],
                       let unlocked = achData["unlocked"] as? Bool {
                        var updated = achievement
                        updated.unlocked = unlocked
                        
                        if let dateString = achData["unlockedDate"] as? String {
                            updated.unlockedDate = dateString
                        }
                        
                        return updated
                    }

                    return achievement
                }
            }

            if let skillsDict = data["skills"] as? [String: [String: Any]] {
                let updatedSkills = skillXPs.map { skill -> SkillXP in
                    if let values = skillsDict[skill.name] {
                        let level = values["level"] as? Int ?? skill.level
                        let xp = values["xp"] as? Int ?? skill.xp
                        return SkillXP(name: skill.name, level: level, xp: xp)
                    } else {
                        return skill
                    }
                }
                
                skillXPs = updatedSkills
                for skill in updatedSkills {
                    animatedSkillProgress[skill.name] = skill.xpProgress
                }
            }
            
            updateAchievements()
        }
    }
    
    private func updateAchievements() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        achievements = achievements.map { achievement in
            var updated = achievement

            switch achievement.index {
            // --- Rank based ---
            case 1 where currentRankId >= 2: // Initiate
                updated.unlocked = true
            case 2 where currentRankId >= 3: // Pioneer
                updated.unlocked = true
            case 3 where currentRankId >= 4: // Explorer
                updated.unlocked = true
            case 4 where currentRankId >= 5: // Challenger
                updated.unlocked = true
            case 5 where currentRankId >= 6: // Refiner
                updated.unlocked = true
            case 6 where currentRankId >= 7: // Master
                updated.unlocked = true
            case 7 where currentRankId >= 8: // Conquerer
                updated.unlocked = true
            case 8 where currentRankId >= 9: // Ascendant
                updated.unlocked = true
            case 9 where currentRankId >= 10: // Transcendent
                updated.unlocked = true

            // --- Progression based ---
            case 10 where currentXP > 0: // First Steps
                updated.unlocked = true
            case 11 where skillXPs.first(where: { $0.name == "Discipline" })?.level ?? 0 >= 10:
                updated.unlocked = true
            case 12 where skillXPs.first(where: { $0.name == "Fitness" })?.level ?? 0 >= 10:
                updated.unlocked = true
            case 13 where skillXPs.first(where: { $0.name == "Fuel" })?.level ?? 0 >= 10:
                updated.unlocked = true
            case 14 where skillXPs.first(where: { $0.name == "Network" })?.level ?? 0 >= 10:
                updated.unlocked = true
            case 15 where skillXPs.first(where: { $0.name == "Resilience" })?.level ?? 0 >= 10:
                updated.unlocked = true
            case 16 where skillXPs.first(where: { $0.name == "Wisdom" })?.level ?? 0 >= 10:
                updated.unlocked = true

            default:
                break
            }

            if updated.unlocked && updated.unlockedDate == nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let monthYear = formatter.string(from: Date())

                updated.unlockedDate = monthYear
                
                userRef.setData([
                    "achievements.\(updated.index)" : [
                        "unlocked": true,
                        "unlockedDate": monthYear
                    ]
                ], merge: true)
            }


            return updated
        }
    }
}

// MARK: - Subviews

struct CurrentRankView: View {
    let currentRank: Rank
    let nextRank: Rank
    let currentXP: Double
    let currentXPProgress: Double
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 16) {
            Image(currentRank.emblemName)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
            
            Text(currentRank.name.uppercased())
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(gradient)
            
            Text(currentRank.subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            ProgressBar(currentXP: currentXP, nextXP: nextRank.requiredXP, progress: currentXPProgress, gradient: gradient)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct ProgressBar: View {
    let currentXP: Double
    let nextXP: Double
    let progress: Double
    let gradient: LinearGradient

    @AppStorage("animationsEnabled") private var animationsEnabled = true

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(Int(currentXP)) XP")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(Int(nextXP)) XP")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 8)
                        .foregroundColor(Color.white.opacity(0.1))
                    
                    Capsule()
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                        .foregroundStyle(gradient)
                        .animation(
                            animationsEnabled ? .easeInOut(duration: 0.5) : nil,
                            value: progress
                        )
                }
            }
            .frame(height: 8)
        }
    }
}


struct NextRankView: View {
    let nextRank: Rank
    @Binding var showPopup: Bool
    
    var body: some View {
        // compute next rank gradient instead
        let nextGradient = LinearGradient(
            colors: nextRank.themeColors,
            startPoint: .leading,
            endPoint: .trailing
        )
        
        return Button {
            showPopup = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next Rank: \(nextRank.name.uppercased())")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(nextGradient) // use next rank gradient
                    
                    Text("Requires \(Int(nextRank.requiredXP)) XP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Image(nextRank.emblemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SkillContributionsView: View {
    let skillXPs: [SkillXP]
    let gradient: LinearGradient
    
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skill Contributions")
                .font(.headline)
                .foregroundStyle(gradient)
            
            Text("This shows each skill's progress towards to your rank.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 12) {
                ForEach(skillXPs) { skill in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(skill.name.uppercased())
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(skill.xp) / \(skill.currentLevelCap) XP")
                                .font(.caption2)
                                .foregroundStyle(gradient)
                        }
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            GeometryReader { geo in
                                Capsule()
                                    .fill(gradient)
                                    .frame(
                                        width: geo.size.width * CGFloat(skill.xpProgress),
                                        height: 8
                                    )
                                    .if(animationsEnabled) { view in
                                        view.animation(.easeInOut(duration: 0.6), value: skill.xpProgress)
                                    }
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}



struct AchievementsView: View {
    let achievements: [Achievement]
    @Binding var selectedAchievement: Achievement?
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(gradient)
            
            Text("You have unlocked \(achievements.filter { $0.unlocked }.count)/\(achievements.count) achievements")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(achievements) { achievement in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()

                        selectedAchievement = achievement
                    } label: {
                        AchievementCard(achievement: achievement)
                    }
                    .buttonStyle(.plain)
                    .disabled(!achievement.unlocked)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
