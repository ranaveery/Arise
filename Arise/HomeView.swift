
import SwiftUI
import Firebase
import FirebaseAuth

struct HomeView: View {
    
    let skillLevelThresholds: [Int] = [
        0,    // Level 1
        150,  // Level 2
        350,  // Level 3
        500,  // Level 4
        850,  // Level 5
        1150, // Level 6
        1500, // Level 7
        2000, // Level 8
        2500, // Level 9
        3350  // Level 10
    ]
    
    let ranks = [
        Rank(id: 1, name: "Seeker", emblemName: "seeker_emblem", requiredXP: 0,
             subtitle: "Every journey begins with a single step.",
             themeColors: [Color(red: 85/255, green: 64/255, blue: 44/255),
                           Color(red: 18/255, green: 13/255, blue: 9/255)]),

        Rank(id: 2, name: "Initiate", emblemName: "initiate_emblem", requiredXP: 900,
             subtitle: "Commitment is your first victory.",
             themeColors: [Color(red: 85/255, green: 85/255, blue: 85/255),
                           Color(red: 169/255, green: 169/255, blue: 169/255)]),

        Rank(id: 3, name: "Pioneer", emblemName: "pioneer_emblem", requiredXP: 2100,
             subtitle: "Forge new paths, leave a mark.",
             themeColors: [Color(red: 184/255, green: 115/255, blue: 51/255),
                           Color(red: 93/255, green: 46/255, blue: 12/255)]),

        Rank(id: 4, name: "Explorer", emblemName: "explorer_emblem", requiredXP: 3000,
             subtitle: "Seek the unknown, learn from everything.",
             themeColors: [Color(red: 153/255, green: 0/255, blue: 0/255),
                           Color(red: 255/255, green: 85/255, blue: 0/255)]),

        Rank(id: 5, name: "Challenger", emblemName: "challenger_emblem", requiredXP: 5100,
             subtitle: "You only lose when you stop fighting.",
             themeColors: [Color(red: 155/255, green: 102/255, blue: 75/255),
                           Color(red: 33/255, green: 64/255, blue: 68/255)]),

        Rank(id: 6, name: "Refiner", emblemName: "refiner_emblem", requiredXP: 6900,
             subtitle: "Strength is forged in relentless practice.",
             themeColors: [Color(red: 4/255, green: 99/255, blue: 7/255),
                           Color(red: 212/255, green: 175/255, blue: 55/255)]),

        Rank(id: 7, name: "Master", emblemName: "master_emblem", requiredXP: 9000,
             subtitle: "Discipline shapes mastery.",
             themeColors: [Color(red: 11/255, green: 29/255, blue: 58/255),
                           Color(red: 64/255, green: 224/255, blue: 208/255)]),

        Rank(id: 8, name: "Conquerer", emblemName: "conquerer_emblem", requiredXP: 12000,
             subtitle: "Pain is the path to triumph.",
             themeColors: [Color(red: 71/255, green: 12/255, blue: 17/255),
                           Color(red: 86/255, green: 105/255, blue: 162/255)]),

        Rank(id: 9, name: "Ascendant", emblemName: "ascendant_emblem", requiredXP: 15000,
             subtitle: "Only by fighting do you rise.",
             themeColors: [Color(red: 10/255, green: 55/255, blue: 126/255),
                           Color(red: 180/255, green: 124/255, blue: 28/255)]),
        

        Rank(id: 10, name: "Transcendent", emblemName: "transcendent_emblem", requiredXP: 20100,
             subtitle: "All limits fall before you.",
             themeColors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                           Color(red: 236/255, green: 71/255, blue: 1/255)])
    ]
    
    @State private var glowPulse = false
    @State private var rank: String = "Loading..."
    @State private var totalXP: Int = 0
    @State private var skillData: [String: [String: Int]] = [:]
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var selectedSkill: IdentifiableSkill? = nil
    @State private var selectedDetent: PresentationDetent = .large
    @State private var showingSkillPopup = false
    
    struct IdentifiableSkill: Identifiable, Hashable {
        var id: String { name }
        let name: String
    }

    private let maxSkillXP: Double = 1000

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
        let formattedTotal = totalXP.formatted(.number.grouping(.automatic))
        if currentRank.id == ranks.last?.id {
            let formattedRequired = Int(currentRank.requiredXP).formatted(.number.grouping(.automatic))
            return "\(formattedTotal) / \(formattedRequired) XP"
        } else {
            let formattedNext = Int(nextRank.requiredXP).formatted(.number.grouping(.automatic))
            return "\(formattedTotal) / \(formattedNext) XP"
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
                                                colors: currentRank.themeColors,
                                                startPoint: .leading,
                                                endPoint: .trailing
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
                                                colors: currentRank.themeColors,
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
                                                    colors: currentRank.themeColors,
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
                                let progress = skillProgress(for: xp)

                                SkillCardView(
                                    symbolName: icon,
                                    skillName: skill,
                                    level: level,
                                    progress: progress,
                                    trend: nil,
                                    destination: nil, // no navigation
                                    gradient: LinearGradient(
                                        colors: currentRank.themeColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    onTap: {
                                        selectedSkill = IdentifiableSkill(name: skill)
                                    }
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
            .sheet(item: $selectedSkill) { skill in
                SkillDetailPopup(
                    symbolName: skillIcons[skill.name] ?? "questionmark.circle",
                    skillName: skill.name,
                    skillXP: skillData[skill.name]?["xp"] ?? 0,
                    skillLevel: skillData[skill.name]?["level"] ?? 1,
                    themeColors: currentRank.themeColors
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onAppear {
                    selectedDetent = .large
                }
            }

        }
    }
    
    func updateSkillLevelsAndTotalXP() {
        var newSkillData: [String: [String: Int]] = [:]
        var accumulatedXP = 0
        
        for (skill, values) in skillData {
            let xp = values["xp"] ?? 0
            let newLevel = calculateSkillLevel(from: xp)
            accumulatedXP += xp
            newSkillData[skill] = ["xp": xp, "level": newLevel]
        }
        
        self.skillData = newSkillData
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.updateData([
            "xp": accumulatedXP,
            "skills": newSkillData
        ]) { error in
            if let error = error {
                print("Failed to update XP in Firestore: \(error.localizedDescription)")
            } else {
                print("Updated total XP in Firestore: \(accumulatedXP)")
            }
        }
    }

    
    func calculateSkillLevel(from xp: Int) -> Int {
        for (index, threshold) in skillLevelThresholds.enumerated().reversed() {
            if xp >= threshold {
                return index + 1 // Levels 1–10
            }
        }
        return 1
    }
    
    func skillProgress(for xp: Int) -> Double {
        let level = calculateSkillLevel(from: xp)
        let currentThreshold = skillLevelThresholds[level - 1]
        let nextThreshold = level < skillLevelThresholds.count
            ? skillLevelThresholds[level]
            : skillLevelThresholds.last! // max level
        
        let range = nextThreshold - currentThreshold
        guard range > 0 else { return 1 } // already maxed
        
        let progress = Double(xp - currentThreshold) / Double(range)
        return min(max(progress, 0), 1.0)
    }

    func addXP(to skill: String, amount: Int) {
        var xp = skillData[skill]?["xp"] ?? 0
        xp += amount
        skillData[skill]?["xp"] = xp
        skillData[skill]?["level"] = calculateSkillLevel(from: xp)
        
        updateSkillLevelsAndTotalXP()
        
    }
    
    private func syncRankIfNeeded() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        // Get what rank Firestore has
        userRef.getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            let firestoreRank = data["rank"] as? String ?? "Seeker"
            
            // Compare with currentRank
            if firestoreRank != currentRank.name {
                userRef.updateData([
                    "rank": currentRank.name
                ]) { error in
                    if let error = error {
                        print("Failed to update rank in Firestore: \(error.localizedDescription)")
                    } else {
                        print("Updated rank in Firestore to \(currentRank.name)")
                    }
                }
            }
        }
    }
    func safeForUserDefaults(_ dict: [String: Any]) -> [String: Any] {
        var safe = [String: Any]()
        
        for (key, value) in dict {
            if let ts = value as? Timestamp {
                // convert to month-year string
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                safe[key] = formatter.string(from: ts.dateValue())
            } else if let subDict = value as? [String: Any] {
                safe[key] = safeForUserDefaults(subDict) // recursive
            } else {
                safe[key] = value
            }
        }
        
        return safe
    }

    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(uid)

        // Realtime listener instead of getDocument
        docRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else { return }

            print("Realtime update from Firestore.")
            self.rank = data["rank"] as? String ?? "Novice"
            self.totalXP = data["xp"] as? Int ?? 0
            self.skillData = data["skills"] as? [String: [String: Int]] ?? [:]
            
            updateSkillLevelsAndTotalXP()
            syncRankIfNeeded()
            let safeData = safeForUserDefaults(data)
            UserDefaults.standard.set(safeData, forKey: "cachedUserData")
        }
    }
}

struct SkillDetailPopup: View {
    let symbolName: String
    let skillName: String
    let skillXP: Int
    let skillLevel: Int
    let themeColors: [Color]
    
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var animatedProgress: Double = 0
    
    private let skillLevelThresholds: [Int] = [
        0, 150, 350, 500, 850, 1150, 1500, 2000, 2500, 3350
    ]
    
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
    
    var body: some View {
        ZStack {
            // Background blur + gradient glow
            LinearGradient(colors: [.black, .black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                Spacer().frame(height: 30)
                
                // --- Title with SF Symbol ---
                HStack(spacing: 10) {
                    Image(systemName: symbolName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                        )
                    Text(skillName)
                        .font(.title.bold())
                        .foregroundStyle(
                            LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding(.top, 8)
                
                Text("Level \(skillLevel)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                // --- XP Progress ---
                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 10)
                        
                        GeometryReader { geo in
                            Capsule()
                                .fill(LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * animatedProgress, height: 10)
                                .shadow(color: themeColors.first?.opacity(0.6) ?? .purple.opacity(0.6), radius: 8, y: 2)
                                .animation(animationsEnabled ? .easeOut(duration: 1.2) : nil, value: animatedProgress)
                        }
                        .frame(height: 10)
                    }
                    .padding(.horizontal, 40)
                    
                    if skillLevel < skillLevelThresholds.count {
                        Text("\(skillXP - currentThreshold) / \(nextThreshold - currentThreshold) XP")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.65))
                    } else {
                        Text("Max Level Reached")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                VStack(spacing: 12) {
                    ForEach(1...skillLevelThresholds.count, id: \.self) { level in
                        let lower = skillLevelThresholds[level - 1]
                        let upper = level < skillLevelThresholds.count
                            ? skillLevelThresholds[level] - 1 // fix overlap
                            : skillLevelThresholds.last ?? lower
                        let isCurrent = level == skillLevel
                        
                        HStack {
                            Text("Level \(level)")
                                .fontWeight(isCurrent ? .bold : .regular)
                                .foregroundColor(isCurrent ? (themeColors.first ?? .white) : .white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(lower) – \(upper) XP")
                                .font(.caption)
                                .foregroundColor(.white.opacity(isCurrent ? 0.9 : 0.5))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isCurrent ? Color.white.opacity(0.05) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isCurrent
                                                ? LinearGradient(colors: themeColors, startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                                            lineWidth: 0.8
                                        )
                                )
                        )
                        .shadow(color: isCurrent ? (themeColors.first?.opacity(0.3) ?? .purple.opacity(0.3)) : .clear, radius: 6, y: 2)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .presentationCornerRadius(30)
        .onAppear {
            animatedProgress = 0
            if animationsEnabled {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedProgress = progressToNext
                }
            } else {
                animatedProgress = progressToNext
            }
        }

    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
