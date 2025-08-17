
import SwiftUI
import Firebase
import FirebaseAuth

struct HomeView: View {
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

                                    Image("master_emblem")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 130, height: 130)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(rank.uppercased())
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

                                    Text("\(totalXP) XP")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))

                                    // XP Bar
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .frame(width: 180, height: 8)
                                            .foregroundColor(Color.white.opacity(0.1))

                                        Capsule()
                                            .frame(width: CGFloat(Double(totalXP % 16000) / 16000) * 180, height: 8)
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
