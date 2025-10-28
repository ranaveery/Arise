import SwiftUI

struct AchievementPopupView: View {
    let achievement: Achievement
    let ranks: [Rank]
    let currentRankId: Int
    
    private let appGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                Spacer(minLength: 10)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 350, height: 350)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(achievement.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 350, height: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .clipped()
                }
                
                    Text(achievement.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                
                    VStack(spacing: 12) {
                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("“\(achievement.quote)”")
                            .font(.callout.italic())
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        if let dateString = achievement.unlockedDate {
                            Text("Unlocked \(dateString)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Got it")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(appGradient, lineWidth: 2.5) //
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(Color.black.ignoresSafeArea())
    }
}
