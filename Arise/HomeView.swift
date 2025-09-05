
import SwiftUI
import Firebase
import FirebaseAuth

struct HomeView: View {
    
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
    
    @State private var glowPulse = false
    @State private var rank: String = "Loading..."
    @State private var totalXP: Int = 0
    @State private var skillData: [String: [String: Int]] = [:]  // [skill: ["level": Int, "xp": Int]]

    private let maxSkillXP: Double = 1000  // Example XP cap per level for % bar

    let skillIcons: [String: String] = [
        "Resilience": "brain",
        "Fuel": "fork.knife",
        "Fitness": "figure.run",
        "Wisdom": "book.fill",
        "Discipline": "infinity",
        "Network": "person.2.fill"
    ]

    private var currentRank: Rank {
        ranks.last(where: { Double(totalXP) >= $0.requiredXP }) ?? ranks[0]
    }
    private var nextRank: Rank {
        ranks.first(where: { $0.requiredXP > Double(totalXP) }) ?? currentRank
    }
    private var xpProgress: Double {
        let prevXP = currentRank.requiredXP
        let nextXP = nextRank.requiredXP
        guard nextXP > prevXP else { return 1 } // at max rank, full bar
        let progress = (Double(totalXP) - prevXP) / Double(nextXP - prevXP)
        return min(max(progress, 0), 1)
    }
    private var xpDisplay: String {
        if currentRank.id == ranks.last?.id {
            return "\(totalXP) / \(Int(currentRank.requiredXP)) XP"
        } else {
            return "\(totalXP) / \(Int(nextRank.requiredXP)) XP"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // RANK HEADER
                        NavigationLink(destination: RankDetailsView()) {
                            HStack(alignment: .center, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 153/255, green: 0/255, blue: 0/255),
                                                    Color(red: 255/255, green: 85/255, blue: 0/255)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(glowPulse ? 1 : 0.9)
                                        .opacity(glowPulse ? 0.5 : 0.4)
                                        .blur(radius: 30)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                                    Image(currentRank.emblemName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 130, height: 130 )
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(currentRank.name.uppercased())
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
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

                                    Text(xpDisplay)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))

                                    // XP Bar
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .frame(width: 180, height: 8)
                                            .foregroundColor(Color.white.opacity(0.1))

                                        Capsule()
                                            .frame(width: 180 * xpProgress, height: 8)
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

                                Spacer()
                            }
                            .padding()
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        // SKILL CARDS
                        VStack(spacing: 15) {
                            ForEach(skillIcons.sorted(by: { $0.key < $1.key }), id: \.key) { skill, icon in
                                let level = skillData[skill]?["level"] ?? 1
                                let xp = skillData[skill]?["xp"] ?? 0
                                let progress = min(Double(xp) / maxSkillXP, 1.0)

                                SkillCardView(
                                    symbolName: icon,
                                    skillName: skill,
                                    level: level,
                                    progress: progress,
                                    trend: nil, // Optional: hook in trends later
                                    destination: AnyView(Text("\(skill) Details")) // Replace with real view
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                glowPulse = true
                fetchUserData()
            }
        }
    }
    
    func fetchUserData() {
        // First try loading from cache
        if let cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") {
            print("Loaded user data from cache.")
            self.rank = cached["rank"] as? String ?? "Novice"
            self.totalXP = cached["xp"] as? Int ?? 0
            self.skillData = cached["skills"] as? [String: [String: Int]] ?? [:]
        }

        // Then try updating from Firestore (runs in background)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(uid)

        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                print("Pulled fresh data from Firestore.")
                self.rank = data["rank"] as? String ?? "Novice"
                self.totalXP = data["xp"] as? Int ?? 0
                self.skillData = data["skills"] as? [String: [String: Int]] ?? [:]

                // Save to cache
                UserDefaults.standard.set(data, forKey: "cachedUserData")
            } else {
                print("Failed to fetch Firestore data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

}
