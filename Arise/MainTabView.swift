import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var selectedTab: Tab = .home
    @State private var showCelebration = false
    @State private var celebrationRank: Rank? = nil
    @State private var celebrationPrevRank: Rank? = nil
    
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
                    LoggingView(showCelebration: $showCelebration, celebrationRank: $celebrationRank, celebrationPrevRank: $celebrationPrevRank)
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
                .frame(height: 55)
                .background(Color.black)
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .bottom)

            // Celebration overlay
            if showCelebration, let rank = celebrationRank {
                RankUpCelebrationView(
                    rank: rank,
                    previousRank: celebrationPrevRank,
                    onDismiss: { showCelebration = false }
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.3), value: showCelebration)
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
                selectedTab = tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isAnimating = false
                }
            } else {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 32, height: 32)

                    Image(systemName: displayedIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
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
