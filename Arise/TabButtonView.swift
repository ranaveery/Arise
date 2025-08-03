import SwiftUI

struct TabButtonView: View {
    let icon: String
    let label: String
    let tab: MainTabView.Tab
    @Binding var selectedTab: MainTabView.Tab
    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            if selectedTab != tab {
                isAnimating = true
                selectedTab = tab

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isAnimating = false
                }
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 32, height: 32)

                    // Use .fill icon if selected
                    Image(systemName: selectedTab == tab ? "\(icon).fill" : icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(.easeOut(duration: 0.2), value: isAnimating)
                }

                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(selectedTab == tab ? 1.0 : 0.7))
            }
            .padding(.top, 6)
        }
    }
}
