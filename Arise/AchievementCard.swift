import SwiftUI

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            if achievement.unlocked {
                // Use your custom emblem from Assets
                Image(achievement.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            } else {
                // Locked state with question mark
                Image(systemName: "questionmark")
                    .font(.title2.bold())
                    .foregroundStyle(.gray)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
