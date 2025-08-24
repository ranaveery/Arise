import SwiftUI
import FirebaseAuth
import Firebase

struct SkillXP: Identifiable {
    let id = UUID()
    let name: String
    let level: Int
    let xp: Int
    var xpProgress: Double {
        min(Double(xp % 1000) / 1000.0, 1.0)  // Example: 1000 XP per level
    }
}

struct Rank: Identifiable {
    let id: Int
    let name: String
    let emblemName: String
    let requiredXP: Double
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
        Rectangle()
            .fill(Color.gray.opacity(0.1)) // darker box
            .aspectRatio(1, contentMode: .fit) // makes it a square
                        .overlay(
                            Image(systemName: achievement.unlocked ? "star.fill" : "questionmark")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                        )
    }
}

struct RankDetailsView: View {
    let ranks = [
        Rank(id: 1, name: "Seeker", emblemName: "star.circle.fill", requiredXP: 0),
        Rank(id: 2, name: "Initiate", emblemName: "circle.fill", requiredXP: 2000),
        Rank(id: 3, name: "Pioneer", emblemName: "circle.fill", requiredXP: 4000),
        Rank(id: 4, name: "Explorer", emblemName: "circle.fill", requiredXP: 8000),
        Rank(id: 5, name: "Challenger", emblemName: "circle.fill", requiredXP: 12000),
        Rank(id: 6, name: "Refiner", emblemName: "circle.fill", requiredXP: 16000),
        Rank(id: 7, name: "Master", emblemName: "circle.fill", requiredXP: 18000),
        Rank(id: 8, name: "Conquerer", emblemName: "circle.fill", requiredXP: 19000),
        Rank(id: 9, name: "Ascendant", emblemName: "circle.fill", requiredXP: 19500),
        Rank(id: 10, name: "Transcendent", emblemName: "circle.fill", requiredXP: 19800),
    ]

    @State private var currentXP: Double = 0
    @State private var currentRankId: Int = 1
    
    @State private var skillXPs: [SkillXP] = [
        SkillXP(name: "Discipline", level: 1, xp: 0),
        SkillXP(name: "Fitness", level: 1, xp: 0),
        SkillXP(name: "Fuel", level: 1, xp: 0),
        SkillXP(name: "Network", level: 1, xp: 0),
        SkillXP(name: "Resilience", level: 1, xp: 0),
        SkillXP(name: "Wisdom", level: 1, xp: 0)

    ]
    
    @State private var glowPulse = false
    
    // achievements state
    @State private var achievements: [Achievement] =
        (1...36).map { Achievement(index: $0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Current rank Section
                VStack(spacing: 6) {
                    Text("Your current rank is:")
                        .font(.caption)
                        .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))

                    Text(currentRank.name.uppercased())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))

                    HStack {
                        Text("\(Int(currentXP)) XP")
                            .font(.caption2)
                            .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))
                        Spacer()
                        Text("\(Int(nextRank.requiredXP)) XP")
                            .font(.caption2)
                            .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))
                    }
                    .padding(.horizontal, 75)

                    HStack(spacing: 12) {
                        Image("master_emblem")
                            .resizable()
                            .frame(width: 60, height: 60)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 14)
                                    .cornerRadius(4)
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

                                Rectangle()
                                    .frame(width: geo.size.width * CGFloat(currentXPProgress), height: 14)
                                    .cornerRadius(4)
                                    .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))
                            }
                        }
                        .frame(height: 14)

                        Image("transcendent_emblem")
                            .resizable()
                            .frame(width: 60, height: 60)
                    }
                    .frame(height: 60)
                }

                // MARK: - Skill Contributions
                VStack(alignment: .leading, spacing: 20) {
                    Text("Skill Contributions")
                        .font(.headline)
                        .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))

                    Text("This shows how much each skill has contributed to your rank")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    ForEach(skillXPs) { skill in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(skill.name.uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(skill.xp) / 1000 XP")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 1, green: 65/255, blue: 74/255))
                                        .frame(width: geo.size.width * CGFloat(skill.xpProgress), height: 12)
                                        .animation(.easeInOut(duration: 0.4), value: skill.xpProgress)
                                }
                            }
                            .frame(height: 12)
                        }
                    }
                }
                
                
                // MARK: - Achievements Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(Color(red: 1, green: 65/255, blue: 74/255))
                    
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
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            glowPulse = true
            loadUserData()
        }
    }

    private var currentRank: Rank {
        ranks.first(where: { $0.id == currentRankId }) ?? ranks[0]
    }

    private var nextRank: Rank {
        ranks.first(where: { $0.id == currentRankId + 1 }) ?? currentRank
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
                // Update existing skills, keep defaults if missing
                self.skillXPs = self.skillXPs.map { skill in
                    if let values = skillsDict[skill.name] {
                        let level = values["level"] as? Int ?? skill.level
                        let xp = values["xp"] as? Int ?? skill.xp
                        return SkillXP(name: skill.name, level: level, xp: xp)
                    } else {
                        return skill // keep default 0 XP
                    }
                }
            }
        }
    }
}
