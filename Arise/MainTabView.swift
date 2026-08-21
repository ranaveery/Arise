import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var selectedTab: Tab = .home
    @State private var resetTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @AppStorage("unlockedAchievementIndices") private var unlockedAchievementData: Data = Data()
    private var unlockedAchievementIndices: Set<Int> {
        get { (try? JSONDecoder().decode(Set<Int>.self, from: unlockedAchievementData)) ?? [] }
        set { if let encoded = try? JSONEncoder().encode(newValue) { unlockedAchievementData = encoded } }
    }

    // Celebration queue
    @State private var celebrationQueue: [CelebrationEvent] = []
    @State private var showingRankUp = false
    @State private var currentRankUpRank: Rank? = nil
    @State private var currentRankUpPrevRank: Rank? = nil
    @State private var showingAchievement = false
    @State private var currentAchievement: Achievement? = nil

    enum Tab {
        case home, logging, trends, settings
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ZStack {
                if selectedTab == .home {
                    HomeView()
                } else if selectedTab == .logging {
                    LoggingView(onCelebrationEvent: { event in
                        Task { @MainActor in
                            celebrationQueue.append(event)
                            dequeueNextCelebration()
                        }
                    })
                } else if selectedTab == .trends {
                    TrendsView()
                } else if selectedTab == .settings {
                    SettingsView(isUserLoggedIn: $isUserLoggedIn)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())

            // Custom Tab Bar
            VStack(spacing: 0) {
                Divider().background(Color.gray.opacity(0.2))

                HStack {
                    TabButton(icon: "house", label: "Home", tab: .home, selectedTab: $selectedTab, animationsEnabled: animationsEnabled)
                    Spacer()
                    TabButton(icon: "list.bullet.clipboard", label: "Tasks", tab: .logging, selectedTab: $selectedTab, animationsEnabled: animationsEnabled)
                    Spacer()
                    TabButton(icon: "chart.bar", label: "Progress", tab: .trends, selectedTab: $selectedTab, animationsEnabled: animationsEnabled)
                    Spacer()
                    TabButton(icon: "gearshape", label: "Settings", tab: .settings, selectedTab: $selectedTab, animationsEnabled: animationsEnabled)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 12)
                .frame(height: 88)
                .background(Color.black)
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .bottom)

            // Celebration overlays
            if showingRankUp, let rank = currentRankUpRank {
                RankUpCelebrationView(
                    rank: rank,
                    previousRank: currentRankUpPrevRank,
                    onDismiss: {
                        showingRankUp = false
                        dequeueNextCelebration()
                    }
                )
                .accessibilityAddTraits(.isModal)
            }
            if showingAchievement, let achievement = currentAchievement {
                AchievementCelebrationView(
                    achievement: achievement,
                    onDismiss: {
                        showingAchievement = false
                        dequeueNextCelebration()
                    }
                )
                .accessibilityAddTraits(.isModal)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.3), value: showingRankUp)
        .animation(.easeOut(duration: 0.3), value: showingAchievement)
        .onAppear {
            migrateAchievementIndicesIfNeeded()
            checkSessionGapAchievements()
            runDailyResetIfNeeded()
        }
        .onReceive(resetTimer) { _ in
            runDailyResetIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                runDailyResetIfNeeded()
            }
        }
    }

    private func dequeueNextCelebration() {
        guard !showingRankUp, !showingAchievement, !celebrationQueue.isEmpty else { return }
        let next = celebrationQueue.removeFirst()

        switch next {
        case .rankUp(let rank, let prevRank):
            currentRankUpRank = rank
            currentRankUpPrevRank = prevRank
            showingRankUp = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .achievement(let achievement):
            currentAchievement = achievement
            showingAchievement = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    private func runDailyResetIfNeeded() {
        DailyReset.performIfNeeded()
    }

    private func migrateAchievementIndicesIfNeeded() {
        let key = "achievementIndicesMigrated"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.removeObject(forKey: "unlockedAchievementIndices")
        UserDefaults.standard.set(true, forKey: key)
    }

    private func checkSessionGapAchievements() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("users").document(uid)
        ref.getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            let firestoreAchievements = data["achievements"] as? [String: [String: Any]] ?? [:]
            let existing = UserDefaults.standard.data(forKey: "unlockedAchievementIndices").flatMap({ try? JSONDecoder().decode(Set<Int>.self, from: $0) }) ?? []
            var storedSoFar = existing

            for (indexStr, achData) in firestoreAchievements {
                guard let index = Int(indexStr),
                      let unlocked = achData["unlocked"] as? Bool,
                      unlocked,
                      !existing.contains(index) else { continue }

                storedSoFar.insert(index)
            }

            let newlyFound = storedSoFar.subtracting(existing)
            if !newlyFound.isEmpty {
                if let encoded = try? JSONEncoder().encode(storedSoFar) {
                    UserDefaults.standard.set(encoded, forKey: "unlockedAchievementIndices")
                }

                let newlyFoundAchievements = newlyFound.sorted().compactMap { idx in
                    allAchievements.first(where: { $0.index == idx })
                }

                Task { @MainActor in
                    for achievement in newlyFoundAchievements {
                        self.celebrationQueue.append(.achievement(achievement))
                    }
                    self.dequeueNextCelebration()
                }
            }
        }
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let tab: MainTabView.Tab
    @Binding var selectedTab: MainTabView.Tab
    let animationsEnabled: Bool
    
    @State private var isAnimating = false

    var body: some View {
        let isSelected = selectedTab == tab
        let displayedIcon = isSelected ? icon + ".fill" : icon

        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            if animationsEnabled {
                isAnimating = true
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedTab = tab
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isAnimating = false
                }
            } else {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 36, height: 36)

                    Image(systemName: displayedIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                        .foregroundColor(.white)
                        .contentTransition(.symbolEffect(.replace))
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(
                            animationsEnabled ? .easeOut(duration: 0.2) : nil,
                            value: isAnimating
                        )
                }

                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .padding(.top, 6)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
