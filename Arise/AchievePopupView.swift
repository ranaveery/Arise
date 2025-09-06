//import SwiftUI
//
//struct AchievementPopupView: View {
//    let achievement: Achievement
//    let ranks: [Rank]
//    let currentRankId: Int
//    
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 24) {
//                
//                Spacer(minLength: 40) // Push content down
//                
//                // Image Card
//                Group {
//                    if achievement.unlocked {
//                        Image(achievement.imageName)
//                            .resizable()
//                            .scaledToFit()
//                    } else {
//                        Image(systemName: "questionmark")
//                            .resizable()
//                            .scaledToFit()
//                            .foregroundColor(.white.opacity(0.7))
//                            .padding(40) // so ? isn't tiny
//                    }
//                }
//                .frame(maxWidth: .infinity, minHeight: 250)
//                .background(Color.clear)
//                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20)
//                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
//                )
//                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
//                
//                if achievement.unlocked {
//                    // Title
//                    Text(achievement.title)
//                        .font(.title2.bold())
//                        .foregroundColor(.white)
//                    
//                    // Text Card
//                    VStack(spacing: 12) {
//                        Text(achievement.description)
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .multilineTextAlignment(.center)
//                        
//                        Text("“\(achievement.quote)”")
//                            .font(.callout.italic())
//                            .foregroundColor(.white.opacity(0.8))
//                            .multilineTextAlignment(.center)
//                        
//                        if let date = achievement.unlockedDate {
//                            Text("Unlocked on \(date.formatted(date: .abbreviated, time: .omitted))")
//                                .font(.caption)
//                                .foregroundColor(.white.opacity(0.6))
//                        }
//                    }
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.white.opacity(0.05))
//                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
//                    
//                } else {
//                    // Goal Card
//                    VStack(spacing: 12) {
//                        Text("Goal:")
//                            .font(.subheadline.bold())
//                            .foregroundColor(.white.opacity(0.8))
//                        
//                        Text(achievement.description)
//                            .font(.caption)
//                            .foregroundColor(.white.opacity(0.6))
//                            .multilineTextAlignment(.center)
//                    }
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.white.opacity(0.05))
//                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
//                }
//                
//                // Got It Button
//                Button(action: {
//                    dismiss()
//                }) {
//                    Text("Got it")
//                        .font(.headline.bold())
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.white.opacity(0.05))
//                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
//                }
//                
//                Spacer(minLength: 40)
//            }
//            .padding()
//        }
//        .background(Color.black.ignoresSafeArea())
//    }
//}

import SwiftUI

struct AchievementPopupView: View {
    let achievement: Achievement
    let ranks: [Rank]
    let currentRankId: Int
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                Spacer(minLength: 40)
                
                // Image Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 350, height: 350) // larger square
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    if achievement.unlocked {
                        Image(achievement.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300) // slightly smaller than card for padding
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        Image(systemName: "questionmark")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 150, height: 150) // bigger ? for balance
                    }
                }
                
                if achievement.unlocked {
                    // Title
                    Text(achievement.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    // Text Card
                    VStack(spacing: 12) {
                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("“\(achievement.quote)”")
                            .font(.callout.italic())
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        if let date = achievement.unlockedDate {
                            Text("Unlocked on \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                } else {
                    // Goal Card
                    VStack(spacing: 12) {
                        Text("Goal:")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                // Got It Button
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
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}
