// CustomTabView.swift
import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
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
                    TabButtonView(icon: "house", label: "Home", tab: .home, selectedTab: $selectedTab)
                    Spacer()
                    TabButtonView(icon: "list.bullet.clipboard", label: "Tasks", tab: .logging, selectedTab: $selectedTab)
                    Spacer()
                    TabButtonView(icon: "chart.bar", label: "Trend", tab: .trends, selectedTab: $selectedTab)
                    Spacer()
                    TabButtonView(icon: "gearshape", label: "Settings", tab: .settings, selectedTab: $selectedTab)
                }
                .padding(.horizontal, 30)
                .frame(height: 55) // Controls total tab bar height
                .background(Color.black)
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }


    func tabButton(icon: String, label: String, tab: Tab) -> some View {
        @State var isAnimating = false

        return Button(action: {
            // Trigger animation
            isAnimating = true
            selectedTab = tab

            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAnimating = false
            }

        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .overlay(
                            selectedTab == tab ? LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 84/255, green: 0/255, blue: 232/255),
                                    Color(red: 236/255, green: 71/255, blue: 1/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .mask(
                                Image(systemName: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            ) : nil
                        )
                        .scaleEffect(isAnimating ? 1.3 : 1.0) // Add scale animation
                        .animation(.easeOut(duration: 0.2), value: isAnimating)
                }

                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(selectedTab == tab ? .clear : .white.opacity(0.7))
                    .overlay(
                        selectedTab == tab ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Text(label)
                                .font(.caption2)
                                .fontWeight(.medium)
                        ) : nil
                    )
            }
            .padding(.top, 6)
        }
    }


}
