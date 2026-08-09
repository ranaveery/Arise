import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var selectedTab: Tab = .home
    @State private var showCelebration = false
    @State private var celebrationRank: Rank? = nil
    @State private var celebrationPrevRank: Rank? = nil
    @State private var showAchievementCelebration = false
    @State private var pendingAchievement: Achievement? = nil
    @State private var queuedAchievement: Achievement? = nil
    @State private var resetTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @AppStorage("unlockedAchievementIndices") private var unlockedAchievementData: Data = Data()
    private var unlockedAchievementIndices: Set<Int> {
        get { (try? JSONDecoder().decode(Set<Int>.self, from: unlockedAchievementData)) ?? [] }
        set { if let encoded = try? JSONEncoder().encode(newValue) { unlockedAchievementData = encoded } }
    }
    
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
                    LoggingView(onCelebrationEvent: { [self] event in
                        switch event {
                        case .rankUp(let rank, let prevRank):
                            self.celebrationRank = rank
                            self.celebrationPrevRank = prevRank
                            self.showCelebration = true
                        case .achievement(let achievement):
                            self.pendingAchievement = achievement
                            self.showAchievementCelebration = true
                        case .queuedAchievement(let achievement):
                            self.queuedAchievement = achievement
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
                .frame(height: 76)
                .background(Color.black)
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .bottom)

            // Celebration overlays
            if showCelebration, let rank = celebrationRank {
                RankUpCelebrationView(
                    rank: rank,
                    previousRank: celebrationPrevRank,
                    onDismiss: {
                        showCelebration = false
                        if let queued = queuedAchievement {
                            pendingAchievement = queued
                            queuedAchievement = nil
                            showAchievementCelebration = true
                        }
                    }
                )
            }
            if showAchievementCelebration, let achievement = pendingAchievement {
                AchievementCelebrationView(
                    achievement: achievement,
                    onDismiss: { showAchievementCelebration = false }
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.3), value: showCelebration)
        .animation(.easeOut(duration: 0.3), value: showAchievementCelebration)
        .onAppear {
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

    private func runDailyResetIfNeeded() {
        DailyReset.performIfNeeded()
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

                if let firstIdx = newlyFound.sorted().first,
                   let achievement = allAchievements.first(where: { $0.index == firstIdx }) {
                    Task { @MainActor in
                        self.pendingAchievement = achievement
                        self.showAchievementCelebration = true
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
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
    }
}
