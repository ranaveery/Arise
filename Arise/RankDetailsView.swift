import SwiftUI
import FirebaseAuth
import Firebase

struct SkillXP: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let level: Int
    let xp: Int
    
    var xpProgress: Double {
        min(Double(xp % 1000) / 1000.0, 1.0)
    }
}

struct Rank: Identifiable {
    let id: Int
    let name: String
    let emblemName: String
    let requiredXP: Double
    let subtitle: String
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let index: Int
    var unlocked: Bool = false
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Image(systemName: achievement.unlocked ? "star.fill" : "questionmark")
                .font(.title2.bold())
                .foregroundStyle(
                    achievement.unlocked
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 153/255, green: 0/255, blue: 0/255),
                                Color(red: 255/255, green: 85/255, blue: 0/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color.white.opacity(0.4))
                )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct RankDetailsView: View {
    let ranks = [
        Rank(id: 1, name: "Seeker", emblemName: "master_emblem", requiredXP: 0, subtitle: "Every journey begins with a single step."),
        Rank(id: 2, name: "Initiate", emblemName: "master_emblem", requiredXP: 2000, subtitle: "Commitment is your first victory."),
        Rank(id: 3, name: "Pioneer", emblemName: "master_emblem", requiredXP: 4000, subtitle: "Forge new paths, leave a mark."),
        Rank(id: 4, name: "Explorer", emblemName: "master_emblem", requiredXP: 8000, subtitle: "Seek the unknown, learn from everything."),
        Rank(id: 5, name: "Challenger", emblemName: "challenger_emblem", requiredXP: 12000, subtitle: "You only lose when you stop fighting."),
        Rank(id: 6, name: "Refiner", emblemName: "master_emblem", requiredXP: 16000, subtitle: "Strength is forged in relentless practice."),
        Rank(id: 7, name: "Master", emblemName: "master_emblem", requiredXP: 18000, subtitle: "Discipline shapes mastery."),
        Rank(id: 8, name: "Conquerer", emblemName: "master_emblem", requiredXP: 19000, subtitle: "Pain is the path to triumph."),
        Rank(id: 9, name: "Ascendant", emblemName: "master_emblem", requiredXP: 19500, subtitle: "Only by fighting do you rise."),
        Rank(id: 10, name: "Transcendent", emblemName: "transcendent_emblem", requiredXP: 19800, subtitle: "All limits fall before you.")
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
    
    @State private var glowPulse = false
    @State private var animatedSkillProgress: [String: Double] = [:]
    @State private var achievements: [Achievement] =
        (1...36).map { Achievement(index: $0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
          
                
                // MARK: - Current Rank Section
                VStack(spacing: 16) {
                    
                    Image(currentRank.emblemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140 )
                    
                    Text(currentRank.name.uppercased())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 153/255, green: 0/255, blue: 0/255),
                                    Color(red: 255/255, green: 85/255, blue: 0/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(currentRank.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(Int(currentXP)) XP")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("\(Int(nextRank.requiredXP)) XP")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 153/255, green: 0/255, blue: 0/255),
                                            Color(red: 255/255, green: 85/255, blue: 0/255)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(
                                    width: max(0, (UIScreen.main.bounds.width - 48) * CGFloat(currentXPProgress)),
                                    height: 10
                                )
                                .animation(.easeInOut(duration: 0.5), value: currentXPProgress)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
                
                // MARK: - Next Rank Section
                Button {
                    showRankPopup = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next Rank: \(nextRank.name.uppercased())")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 153/255, green: 0/255, blue: 0/255),
                                            Color(red: 255/255, green: 85/255, blue: 0/255)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
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
                .buttonStyle(.plain) // removes default button styling
                
                
                // MARK: - Skill Contributions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Skill Contributions")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 153/255, green: 0/255, blue: 0/255),
                                    Color(red: 255/255, green: 85/255, blue: 0/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
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
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 153/255, green: 0/255, blue: 0/255),
                                                    Color(red: 255/255, green: 85/255, blue: 0/255)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 153/255, green: 0/255, blue: 0/255),
                                                    Color(red: 255/255, green: 85/255, blue: 0/255)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: max(
                                                0,
                                                (UIScreen.main.bounds.width - 48) *
                                                CGFloat(animatedSkillProgress[skill.name] ?? 0)
                                            ),
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
         
                
                // MARK: - Achievements Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 153/255, green: 0/255, blue: 0/255),
                                    Color(red: 255/255, green: 85/255, blue: 0/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("You have unlocked \(achievements.filter { $0.unlocked }.count)/\(achievements.count) achievements")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                        spacing: 16
                    ) {
                        ForEach(achievements) { achievement in
                            Button {
                                print("Tapped achievement \(achievement.index)")
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
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .sheet(isPresented: $showRankPopup) {
            RankPopupView(ranks: ranks, currentRankId: currentRankId)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            glowPulse = true
            loadUserData()
        }
    }

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

    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching user data: \(error?.localizedDescription ?? "unknown")")
                return
            }

            self.currentXP = Double(data["xp"] as? Int ?? 0)

            if let rankName = data["rank"] as? String,
               let rank = ranks.first(where: { $0.name == rankName }) {
                self.currentRankId = rank.id
            }

            if let skillsDict = data["skills"] as? [String: [String: Any]] {
                let updatedSkills = self.skillXPs.map { skill in
                    if let values = skillsDict[skill.name] {
                        let level = values["level"] as? Int ?? skill.level
                        let xp = values["xp"] as? Int ?? skill.xp
                        return SkillXP(name: skill.name, level: level, xp: xp)
                    } else {
                        return skill
                    }
                }

                // Update skills immediately
                self.skillXPs = updatedSkills

                // Just update progress values without animating the VStack
                for skill in updatedSkills {
                    self.animatedSkillProgress[skill.name] = skill.xpProgress
                }
            }
        }
    }
    
    struct RankPopupView: View {
        let ranks: [Rank]
        let currentRankId: Int
        
        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    Text("All Ranks")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    ForEach(ranks) { rank in
                        HStack(spacing: 12) {
                            // Placeholder emblem
                            Image(rank.emblemName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .opacity(rank.id == currentRankId ? 1 : 0.6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rank.name.uppercased())
                                    .font(.headline)
                                    .foregroundColor(rank.id == currentRankId ? .white : .white.opacity(0.8))
                                
                                Text("Requires \(Int(rank.requiredXP)) XP")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if rank.id == currentRankId {
                                Text("You are here")
                                    .font(.caption2.bold())
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 153/255, green: 0/255, blue: 0/255),
                                                Color(red: 255/255, green: 85/255, blue: 0/255)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(rank.id == currentRankId ? 0.15 : 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
                .background(Color.black.ignoresSafeArea())
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
    }
    
    
    
}
