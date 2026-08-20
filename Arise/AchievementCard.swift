import SwiftUI

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        
        shape
            .fill(Color.white.opacity(0.05))
            .overlay {
                if achievement.unlocked {
                    Image(achievement.imageName)
                        .resizable()
                        .scaledToFill()   // cover the whole square
                        .clipped()        // safety
                        .accessibilityLabel(achievement.title)
                } else {
                    Image(systemName: "questionmark")
                        .font(.title2.bold())
                        .foregroundStyle(.gray)
                        .accessibilityLabel("Locked achievement")
                }
            }
            .clipShape(shape) // keep image inside rounded corners
            .overlay(
                shape.strokeBorder(Color.white.opacity(0.1), lineWidth: 1) // border on top
            )
            .aspectRatio(1, contentMode: .fit)
    }
}
