import SwiftUI

struct RankUpCelebrationView: View {
    let rank: Rank
    let previousRank: Rank?
    let onDismiss: () -> Void

    @State private var transitionStage = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.98)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: rank.themeColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 50)
                            .opacity(transitionStage >= 1 ? 0.7 : 0)

                        if let old = previousRank {
                            Image(old.emblemName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .scaleEffect(transitionStage >= 1 ? 0.5 : 1)
                                .opacity(transitionStage >= 1 ? 0 : 1)
                        }

                        Image(rank.emblemName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .scaleEffect(transitionStage >= 1 ? 1 : 0.3)
                            .opacity(transitionStage >= 1 ? 1 : 0)
                    }

                    VStack(spacing: 6) {
                        Text("RANK UP!")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .tracking(3)
                            .offset(y: transitionStage >= 2 ? 0 : 20)
                            .opacity(transitionStage >= 2 ? 1 : 0)

                        Text(rank.name.uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: rank.themeColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(y: transitionStage >= 2 ? 0 : 30)
                            .opacity(transitionStage >= 2 ? 1 : 0)

                        Text(rank.subtitle)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .offset(y: transitionStage >= 2 ? 0 : 40)
                            .opacity(transitionStage >= 2 ? 1 : 0)
                    }
                    .padding(.top, 20)
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
        if previousRank != nil {
            transitionStage = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                    transitionStage = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        transitionStage = 2
                    }
                }
            }
        } else {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                transitionStage = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    transitionStage = 2
                }
            }
        }
    }
}
