import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var selectedTab: Tab = .home
    
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
                    LoggingView()
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
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
                        .scaleEffect(isAnimating ? 1.3 : 1.0) // same as your original
                        .animation(animationsEnabled ? .easeOut(duration: 0.2) : nil,
                                   value: isAnimating) // conditional animation
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


//import SwiftUI
//
//struct MainTabView: View {
//    @Binding var isUserLoggedIn: Bool
//    @AppStorage("animationsEnabled") private var animationsEnabled = true
//    @State private var selectedTab: Tab = .home
//
//    enum Tab: Hashable {
//        case home, logging, trends, settings
//    }
//
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            HomeView()
//                .tag(Tab.home)
//                .tabItem { Label("Home", systemImage: "house") }
//
//            LoggingView()
//                .tag(Tab.logging)
//                .tabItem { Label("Tasks", systemImage: "list.bullet.clipboard") }
//
//            TrendsView()
//                .tag(Tab.trends)
//                .tabItem { Label("Trend", systemImage: "chart.bar") }
//
//            SettingsView(isUserLoggedIn: $isUserLoggedIn)
//                .tag(Tab.settings)
//                .tabItem { Label("Settings", systemImage: "gearshape") }
//        }
//        // Use the new built-in tab bar style (Liquid Glass) by default
//        .glassEffect()  // apply the glass effect to the entire TabView bar
//        //.glassEffect(in: .whatever) if you want a variant
//        // Optionally, you can add bottom accessory control
//        .tabViewBottomAccessory {
//            // e.g. a floating button or whatever you need
//            // Button(action: ...) { ... }
//        }
//        .tabBarMinimizeBehavior(.onScrollDown)  // shrink behavior
//    }
//}
