//import SwiftUI
//import FirebaseAuth
//import Firebase
//
//struct RankDetailsView: View {
//    let ranks = [
//        Rank(id: 1, name: "Seeker", emblemName: "master_emblem", requiredXP: 0, subtitle: "Every journey begins with a single step."),
//        Rank(id: 2, name: "Initiate", emblemName: "master_emblem", requiredXP: 1000, subtitle: "Commitment is your first victory."),
//        Rank(id: 3, name: "Pioneer", emblemName: "master_emblem", requiredXP: 2000, subtitle: "Forge new paths, leave a mark."),
//        Rank(id: 4, name: "Explorer", emblemName: "master_emblem", requiredXP: 3000, subtitle: "Seek the unknown, learn from everything."),
//        Rank(id: 5, name: "Challenger", emblemName: "challenger_emblem", requiredXP: 5000, subtitle: "You only lose when you stop fighting."),
//        Rank(id: 6, name: "Refiner", emblemName: "master_emblem", requiredXP: 7000, subtitle: "Strength is forged in relentless practice."),
//        Rank(id: 7, name: "Master", emblemName: "master_emblem", requiredXP: 9000, subtitle: "Discipline shapes mastery."),
//        Rank(id: 8, name: "Conquerer", emblemName: "master_emblem", requiredXP: 12000, subtitle: "Pain is the path to triumph."),
//        Rank(id: 9, name: "Ascendant", emblemName: "master_emblem", requiredXP: 15000, subtitle: "Only by fighting do you rise."),
//        Rank(id: 10, name: "Transcendent", emblemName: "transcendent_emblem", requiredXP: 20000, subtitle: "All limits fall before you.")
//    ]
//
//    @State private var currentXP: Double = 0
//    @State private var currentRankId: Int = 1
//    @State private var showRankPopup = false
//    @State private var skillXPs: [SkillXP] = [
//        SkillXP(name: "Discipline", level: 1, xp: 0),
//        SkillXP(name: "Fitness", level: 1, xp: 0),
//        SkillXP(name: "Fuel", level: 1, xp: 0),
//        SkillXP(name: "Network", level: 1, xp: 0),
//        SkillXP(name: "Resilience", level: 1, xp: 0),
//        SkillXP(name: "Wisdom", level: 1, xp: 0)
//    ]
//    
//    @State private var glowPulse = false
//    @State private var selectedAchievement: Achievement? = nil
//    @State private var animatedSkillProgress: [String: Double] = [:]
//    @State private var achievements: [Achievement] = [
//        Achievement(
//            index: 1,
//            title: "First Steps",
//            imageName: "master_emblem", // placeholder image from Assets
//            description: "You earned your very first XP!",
//            quote: "Every journey begins with a single step."
//        ),
//        Achievement(
//            index: 2,
//            title: "Disciplined",
//            imageName: "master_emblem",
//            description: "Reached level 2 in Discipline.",
//            quote: "Consistency beats intensity."
//        ),
//        Achievement(
//            index: 3,
//            title: "Fuel Up",
//            imageName: "master_emblem",
//            description: "Logged your first meal in Fuel.",
//            quote: "What you put in is what you get out."
//        ),
//        Achievement(
//            index: 4,
//            title: "Fuel Up",
//            imageName: "master_emblem",
//            description: "Logged your first meal in Fuel.",
//            quote: "What you put in is what you get out."
//        ),
//        Achievement(
//            index: 5,
//            title: "Fuel Up",
//            imageName: "master_emblem",
//            description: "Logged your first meal in Fuel.",
//            quote: "What you put in is what you get out."
//        ),
//        Achievement(
//            index: 6,
//            title: "Fuel Up",
//            imageName: "master_emblem",
//            description: "Logged your first meal in Fuel.",
//            quote: "What you put in is what you get out."
//        )
//    ]
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 32) {
//                // MARK: - Current Rank Section
//                VStack(spacing: 16) {
//                    
//                    Image(currentRank.emblemName)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 140, height: 140 )
//                    
//                    Text(currentRank.name.uppercased())
//                        .font(.system(size: 28, weight: .bold, design: .rounded))
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [
//                                    Color(red: 153/255, green: 0/255, blue: 0/255),
//                                    Color(red: 255/255, green: 85/255, blue: 0/255)
//                                ],
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                    
//                    Text(currentRank.subtitle)
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.7))
//                        .multilineTextAlignment(.center)
//                    
//                    VStack(spacing: 12) {
//                        HStack {
//                            Text("\(Int(currentXP)) XP")
//                                .font(.caption2)
//                                .foregroundColor(.white.opacity(0.6))
//                            Spacer()
//                            Text("\(Int(nextRank.requiredXP)) XP")
//                                .font(.caption2)
//                                .foregroundColor(.white.opacity(0.6))
//                        }
//                        
//                        ZStack(alignment: .leading) {
//                            Capsule()
//                                .fill(Color.white.opacity(0.1))
//                                .frame(height: 10)
//                            
//                            Capsule()
//                                .fill(
//                                    LinearGradient(
//                                        colors: [
//                                            Color(red: 153/255, green: 0/255, blue: 0/255),
//                                            Color(red: 255/255, green: 85/255, blue: 0/255)
//                                        ],
//                                        startPoint: .leading,
//                                        endPoint: .trailing
//                                    )
//                                )
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .frame(
//                                    width: max(0, (UIScreen.main.bounds.width - 48) * CGFloat(currentXPProgress)),
//                                    height: 10
//                                )
//                                .animation(.easeInOut(duration: 0.5), value: currentXPProgress)
//                        }
//                    }
//                }
//                .padding()
//                .background(Color.white.opacity(0.05))
//                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//            
//                
//                // MARK: - Next Rank Section
//                Button {
//                    showRankPopup = true
//                } label: {
//                    HStack {
//                        VStack(alignment: .leading, spacing: 6) {
//                            Text("Next Rank: \(nextRank.name.uppercased())")
//                                .font(.system(size: 16, weight: .semibold, design: .rounded))
//                                .foregroundStyle(
//                                    LinearGradient(
//                                        colors: [
//                                            Color(red: 153/255, green: 0/255, blue: 0/255),
//                                            Color(red: 255/255, green: 85/255, blue: 0/255)
//                                        ],
//                                        startPoint: .leading,
//                                        endPoint: .trailing
//                                    )
//                                )
//                            
//                            Text("Requires \(Int(nextRank.requiredXP)) XP")
//                                .font(.caption)
//                                .foregroundColor(.white.opacity(0.6))
//                        }
//                        
//                        Spacer()
//
//                        Image(nextRank.emblemName)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 50, height: 50)
//                    }
//                    .padding()
//                    .background(Color.white.opacity(0.05))
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                }
//                .buttonStyle(.plain) // removes default button styling
//                
//                
//                // MARK: - Skill Contributions
//                VStack(alignment: .leading, spacing: 16) {
//                    Text("Skill Contributions")
//                        .font(.headline)
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [
//                                    Color(red: 153/255, green: 0/255, blue: 0/255),
//                                    Color(red: 255/255, green: 85/255, blue: 0/255)
//                                ],
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                    
//                    Text("This shows how much each skill has contributed to your rank.")
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.6))
//                    
//                    VStack(spacing: 12) {
//                        ForEach(skillXPs) { skill in
//                            VStack(alignment: .leading, spacing: 6) {
//                                HStack {
//                                    Text(skill.name.uppercased())
//                                        .font(.subheadline.bold())
//                                        .foregroundColor(.white)
//                                    
//                                    Spacer()
//                                    
//                                    Text("\(skill.xp) / 1000 XP")
//                                        .font(.caption2)
//                                        .foregroundStyle(
//                                            LinearGradient(
//                                                colors: [
//                                                    Color(red: 153/255, green: 0/255, blue: 0/255),
//                                                    Color(red: 255/255, green: 85/255, blue: 0/255)
//                                                ],
//                                                startPoint: .leading,
//                                                endPoint: .trailing
//                                            )
//                                        )
//                                }
//                                
//                                ZStack(alignment: .leading) {
//                                    Capsule()
//                                        .fill(Color.white.opacity(0.1))
//                                        .frame(height: 8)
//                                    
//                                    Capsule()
//                                        .fill(
//                                            LinearGradient(
//                                                colors: [
//                                                    Color(red: 153/255, green: 0/255, blue: 0/255),
//                                                    Color(red: 255/255, green: 85/255, blue: 0/255)
//                                                ],
//                                                startPoint: .leading,
//                                                endPoint: .trailing
//                                            )
//                                        )
//                                        .frame(
//                                            width: max(
//                                                0,
//                                                (UIScreen.main.bounds.width - 48) *
//                                                CGFloat(animatedSkillProgress[skill.name] ?? 0)
//                                            ),
//                                            height: 8
//                                        )
//                                        .animation(.easeInOut(duration: 0.6), value: animatedSkillProgress[skill.name])
//                                }
//                            }
//                        }
//                    }
//                }
//                .padding()
//                .background(Color.white.opacity(0.05))
//                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//         
//                
//                // MARK: - Achievements Section
//                VStack(alignment: .leading, spacing: 16) {
//                    Text("Achievements")
//                        .font(.headline)
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [
//                                    Color(red: 153/255, green: 0/255, blue: 0/255),
//                                    Color(red: 255/255, green: 85/255, blue: 0/255)
//                                ],
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                    
//                    Text("You have unlocked \(achievements.filter { $0.unlocked }.count)/\(achievements.count) achievements")
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.6))
//                    
//                    LazyVGrid(
//                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
//                        spacing: 16
//                    ) {
//                        ForEach(achievements) { achievement in
//                            Button {
//                                selectedAchievement = achievement
//                            } label: {
//                                AchievementCard(achievement: achievement)
//                            }
//                            .buttonStyle(.plain)
//                        }
//                    }
//                }
//                .padding()
//                .background(Color.white.opacity(0.05))
//                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                
//                Spacer(minLength: 40)
//            }
//            .padding()
//        }
//        .sheet(isPresented: $showRankPopup) {
//            RankPopupView(ranks: ranks, currentRankId: currentRankId)
//        }
//        .background(Color.black.ignoresSafeArea())
//        .onAppear {
//            glowPulse = true
//            loadUserData()
//        }
//        .sheet(item: $selectedAchievement) { achievement in
//            AchievementPopupView(achievement: achievement)
//        }
//    }
//
//    private var currentRank: Rank {
//        ranks.last(where: { Double(currentXP) >= $0.requiredXP }) ?? ranks[0]
//    }
//    
//    private var nextRank: Rank {
//        ranks.first(where: { $0.requiredXP > Double(currentXP) }) ?? currentRank
//    }
//
//    private var currentXPProgress: Double {
//        let prevXP = currentRank.requiredXP
//        let nextXP = nextRank.requiredXP
//        return min(max((currentXP - prevXP) / (nextXP - prevXP), 0), 1)
//    }
//
//    private func loadUserData() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//
//        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
//            guard let data = snapshot?.data(), error == nil else {
//                print("Error fetching user data: \(error?.localizedDescription ?? "unknown")")
//                return
//            }
//
//            self.currentXP = Double(data["xp"] as? Int ?? 0)
//
//            if let rankName = data["rank"] as? String,
//               let rank = ranks.first(where: { $0.name == rankName }) {
//                self.currentRankId = rank.id
//            }
//
//            if let skillsDict = data["skills"] as? [String: [String: Any]] {
//                let updatedSkills = self.skillXPs.map { skill in
//                    if let values = skillsDict[skill.name] {
//                        let level = values["level"] as? Int ?? skill.level
//                        let xp = values["xp"] as? Int ?? skill.xp
//                        return SkillXP(name: skill.name, level: level, xp: xp)
//                    } else {
//                        return skill
//                    }
//                }
//
//                self.skillXPs = updatedSkills
//
//                for skill in updatedSkills {
//                    self.animatedSkillProgress[skill.name] = skill.xpProgress
//                }
//            }
//            self.updateAchievements()
//        }
//    }
//    
//    private func updateAchievements() {
//        achievements = achievements.map { achievement in
//            var updated = achievement
//            
//            switch achievement.index {
//            case 1:
//                // Unlock when the user has any XP
//                if currentXP > 0 {
//                    updated.unlocked = true
//                    if updated.unlockedDate == nil {
//                        updated.unlockedDate = Date()
//                    }
//                }
//                
//            case 2:
//                // Unlock when Discipline reaches level 2
//                if let discipline = skillXPs.first(where: { $0.name == "Discipline" }),
//                   discipline.level >= 2 {
//                    updated.unlocked = true
//                    if updated.unlockedDate == nil {
//                        updated.unlockedDate = Date()
//                    }
//                }
//                
//            case 3:
//                // Unlock when user logs any XP in Fuel
//                if let fuel = skillXPs.first(where: { $0.name == "Fuel" }),
//                   fuel.xp > 0 {
//                    updated.unlocked = true
//                    if updated.unlockedDate == nil {
//                        updated.unlockedDate = Date()
//                    }
//                }
//                
//            // Add more achievement rules here
//            default:
//                break
//            }
//            
//            return updated
//        }
//    }
//    
//    
//}
import SwiftUI
import FirebaseAuth
import Firebase

struct RankDetailsView: View {
    let ranks = [
        Rank(id: 1, name: "Seeker", emblemName: "master_emblem", requiredXP: 0, subtitle: "Every journey begins with a single step."),
        Rank(id: 2, name: "Initiate", emblemName: "master_emblem", requiredXP: 1000, subtitle: "Commitment is your first victory."),
        Rank(id: 3, name: "Pioneer", emblemName: "master_emblem", requiredXP: 2000, subtitle: "Forge new paths, leave a mark."),
        Rank(id: 4, name: "Explorer", emblemName: "master_emblem", requiredXP: 3000, subtitle: "Seek the unknown, learn from everything."),
        Rank(id: 5, name: "Challenger", emblemName: "challenger_emblem", requiredXP: 5000, subtitle: "You only lose when you stop fighting."),
        Rank(id: 6, name: "Refiner", emblemName: "master_emblem", requiredXP: 7000, subtitle: "Strength is forged in relentless practice."),
        Rank(id: 7, name: "Master", emblemName: "master_emblem", requiredXP: 9000, subtitle: "Discipline shapes mastery."),
        Rank(id: 8, name: "Conquerer", emblemName: "master_emblem", requiredXP: 12000, subtitle: "Pain is the path to triumph."),
        Rank(id: 9, name: "Ascendant", emblemName: "master_emblem", requiredXP: 15000, subtitle: "Only by fighting do you rise."),
        Rank(id: 10, name: "Transcendent", emblemName: "transcendent_emblem", requiredXP: 20000, subtitle: "All limits fall before you.")
    ]
    
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
    @State private var achievements: [Achievement] = [
        Achievement(index: 1, title: "First Steps", imageName: "master_emblem", description: "You earned your very first XP!", quote: "Every journey begins with a single step."),
        Achievement(index: 2, title: "Disciplined", imageName: "master_emblem", description: "Reached level 2 in Discipline.", quote: "Consistency beats intensity."),
        Achievement(index: 3, title: "Fuel Up", imageName: "master_emblem", description: "Logged your first meal in Fuel.", quote: "What you put in is what you get out."),
        Achievement(index: 4, title: "Fuel Up", imageName: "master_emblem", description: "Logged your first meal in Fuel.", quote: "What you put in is what you get out."),
        Achievement(index: 5, title: "Fuel Up", imageName: "master_emblem", description: "Logged your first meal in Fuel.", quote: "What you put in is what you get out."),
        Achievement(index: 6, title: "Fuel Up", imageName: "master_emblem", description: "Logged your first meal in Fuel.", quote: "What you put in is what you get out.")
    ]
    @State private var glowPulse = false
    @State private var selectedAchievement: Achievement? = nil
    
    // MARK: - Gradient
    private var rankGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 153/255, green: 0, blue: 0),
                     Color(red: 255/255, green: 85/255, blue: 0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                CurrentRankView(currentRank: currentRank, nextRank: nextRank, currentXP: currentXP, currentXPProgress: currentXPProgress, gradient: rankGradient)
                
                NextRankView(nextRank: nextRank, showPopup: $showRankPopup, gradient: rankGradient)
                
                SkillContributionsView(skillXPs: skillXPs, animatedSkillProgress: $animatedSkillProgress, gradient: rankGradient)
                
                AchievementsView(achievements: achievements, selectedAchievement: $selectedAchievement)
                
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
        return min(max((currentXP - prevXP) / (nextXP - prevXP), 0), 1)
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            
            currentXP = Double(data["xp"] as? Int ?? 0)
            
            if let rankName = data["rank"] as? String,
               let rank = ranks.first(where: { $0.name == rankName }) {
                currentRankId = rank.id
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
        achievements = achievements.map { achievement in
            var updated = achievement
            
            switch achievement.index {
            case 1 where currentXP > 0:
                updated.unlocked = true
                if updated.unlockedDate == nil { updated.unlockedDate = Date() }
            case 2 where skillXPs.first(where: { $0.name == "Discipline" })?.level ?? 0 >= 2:
                updated.unlocked = true
                if updated.unlockedDate == nil { updated.unlockedDate = Date() }
            case 3 where skillXPs.first(where: { $0.name == "Fuel" })?.xp ?? 0 > 0:
                updated.unlocked = true
                if updated.unlockedDate == nil { updated.unlockedDate = Date() }
            default:
                break
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
                .font(.system(size: 28, weight: .bold, design: .rounded))
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
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 10)
                
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, (UIScreen.main.bounds.width - 48) * CGFloat(progress)), height: 10)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
    }
}

struct NextRankView: View {
    let nextRank: Rank
    @Binding var showPopup: Bool
    let gradient: LinearGradient
    
    var body: some View {
        Button {
            showPopup = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next Rank: \(nextRank.name.uppercased())")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(gradient)
                    
                    Text("Requires \(Int(nextRank.requiredXP)) XP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Image(nextRank.emblemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
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
    @Binding var animatedSkillProgress: [String: Double]
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skill Contributions")
                .font(.headline)
                .foregroundStyle(gradient)
            
            Text("This shows how much each skill has contributed to your rank.")
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
                            Text("\(skill.xp) / 1000 XP")
                                .font(.caption2)
                                .foregroundStyle(gradient)
                        }
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(gradient)
                                .frame(
                                    width: max(0, (UIScreen.main.bounds.width - 48) * CGFloat(animatedSkillProgress[skill.name] ?? 0)),
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.6), value: animatedSkillProgress[skill.name])
                        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 153/255, green: 0, blue: 0),
                                 Color(red: 255/255, green: 85/255, blue: 0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("You have unlocked \(achievements.filter { $0.unlocked }.count)/\(achievements.count) achievements")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(achievements) { achievement in
                    Button {
                        selectedAchievement = achievement
                    } label: {
                        AchievementCard(achievement: achievement)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
