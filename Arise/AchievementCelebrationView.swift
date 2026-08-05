import SwiftUI

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var transitionStage = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Image(achievement.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .scaleEffect(transitionStage >= 1 ? 1 : 0.3)
                        .opacity(transitionStage >= 1 ? 1 : 0)

                    VStack(spacing: 8) {
                        Text("ACHIEVEMENT UNLOCKED!")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)
                            .offset(y: transitionStage >= 2 ? 0 : 20)
                            .opacity(transitionStage >= 2 ? 1 : 0)

                        Text(achievement.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .offset(y: transitionStage >= 2 ? 0 : 30)
                            .opacity(transitionStage >= 2 ? 1 : 0)

                        Text(achievement.description)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .offset(y: transitionStage >= 2 ? 0 : 40)
                            .opacity(transitionStage >= 2 ? 1 : 0)

                        Text("\"\(achievement.quote)\"")
                            .font(.system(size: 13, design: .rounded).italic())
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .offset(y: transitionStage >= 2 ? 0 : 50)
                            .opacity(transitionStage >= 2 ? 1 : 0)
                    }
                    .padding(.top, 24)
                }

                Spacer()

                Text("Tap anywhere to continue")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(transitionStage >= 1 ? 1 : 0)
                    .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                onDismiss()
            }
        }
        .onAppear {
            animateTransition()
        }
    }

    private func animateTransition() {
        transitionStage = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                transitionStage = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    transitionStage = 2
                }
            }
        }
    }
}
