import SwiftUI

// MARK: - Models for demo

struct Rank: Identifiable {
    let id: Int
    let name: String
    let emblemName: String
    let requiredXP: Double
}

struct SkillXP {
    let name: String
    let xpProgress: Double
}

// MARK: - Main View

struct RankDetails: View {
    // Your exact ranks
    let ranks = [
        Rank(id: 1, name: "Seeker", emblemName: "circle.fill", requiredXP: 2000),
        Rank(id: 2, name: "Initiate", emblemName: "circle.fill", requiredXP: 4000),
        Rank(id: 3, name: "Pioneer", emblemName: "circle.fill", requiredXP: 8000),
        Rank(id: 4, name: "Explorer", emblemName: "circle.fill", requiredXP: 12000),
        Rank(id: 5, name: "Challenger", emblemName: "circle.fill", requiredXP: 16000),
        Rank(id: 6, name: "Refiner", emblemName: "circle.fill", requiredXP: 18000),
        Rank(id: 7, name: "Master", emblemName: "circle.fill", requiredXP: 19000),
        Rank(id: 8, name: "Conquerer", emblemName: "circle.fill", requiredXP: 19500),
        Rank(id: 9, name: "Ascendant", emblemName: "star.circle.fill", requiredXP: 19800),
        Rank(id: 10, name: "Transcendent", emblemName: "star.fill", requiredXP: 20000)
    ]

    // Current user progress (example)
    @State private var currentRankId = 10
    @State private var currentXP: Double = 8300
    @State private var glowPulse = false

    // All 6 skill contributions
    let skillXPs = [
        SkillXP(name: "Resilience", xpProgress: 0.4),
        SkillXP(name: "Fuel", xpProgress: 0.6),
        SkillXP(name: "Fitness", xpProgress: 0.5),
        SkillXP(name: "Wisdom", xpProgress: 0.2),
        SkillXP(name: "Discipline", xpProgress: 0.3),
        SkillXP(name: "Network", xpProgress: 0.99)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Hero Section
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 84/255, green: 0/255, blue: 232/255),
                                        Color(red: 236/255, green: 71/255, blue: 1/255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(glowPulse ? 1 : 0.9)
                            .opacity(glowPulse ? 0.5 : 0.4)
                            .blur(radius: 35)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                        Image("transcendent_emblem")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                    .padding(.top, 40)

                    Text(ranks[currentRankId-1].name.uppercased())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 236/255, green: 71/255, blue: 1/255),
                                    Color(red: 84/255, green: 0/255, blue: 232/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Level \(currentRankId) of \(ranks.count)")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)

                    // XP Progress Bar with animated fill
                    VStack(spacing: 6) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(height: 12)
                                .foregroundColor(Color.white.opacity(0.1))

                            Capsule()
                                .frame(width: CGFloat(currentXP / ranks[currentRankId-1].requiredXP) * 280, height: 12)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 84/255, green: 0/255, blue: 232/255),
                                            Color(red: 236/255, green: 71/255, blue: 1/255)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .animation(.easeInOut, value: currentXP)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(width: 280)

                        Text(String(format: "%.1fK / %.1fK XP", currentXP / 1000, ranks[currentRankId-1].requiredXP / 1000))
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }

                    // Motivational Quote under XP bar
                    Text("“Keep pushing your limits — greatness awaits.”")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                        .padding(.top, 6)
                }

                // MARK: Horizontal Rank Progression Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 28) {
                        ForEach(ranks) { rank in
                            VStack(spacing: 6) {
                                Image(systemName: rank.emblemName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: rank.id == currentRankId ? 48 : 32,
                                           height: rank.id == currentRankId ? 48 : 32)
                                    .foregroundColor(rank.id <= currentRankId ? Color(red: 84/255, green: 0/255, blue: 232/255) : .gray.opacity(0.3))
                                    .scaleEffect(rank.id == currentRankId ? 1.3 : 1)
                                    .shadow(color: rank.id == currentRankId ? Color(red: 236/255, green: 71/255, blue: 1/255).opacity(0.7) : .clear,
                                            radius: 8)
                                    .animation(.easeInOut, value: currentRankId)

                                Text(rank.name)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .opacity(rank.id <= currentRankId ? 1 : 0.4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: Skill Contributions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skill Contributions")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(skillXPs, id: \.name) { skill in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(skill.name)
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Text("\(Int(skill.xpProgress * 100))%")
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .frame(height: 8)
                                        .foregroundColor(Color.white.opacity(0.1))

                                    Capsule()
                                        .frame(width: geo.size.width * CGFloat(skill.xpProgress), height: 8)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 84/255, green: 0/255, blue: 232/255),
                                                    Color(red: 236/255, green: 71/255, blue: 1/255)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .animation(.easeInOut, value: skill.xpProgress)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: Rank History Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rank History")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(ranks.prefix(currentRankId), id: \.id) { rank in
                        HStack(spacing: 12) {
                            Image(systemName: rank.emblemName)
                                .foregroundColor(Color(red: 84/255, green: 0/255, blue: 232/255))
                                .frame(width: 28, height: 28)

                            Text(rank.name)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            if rank.id == currentRankId {
                                Text("Current")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 236/255, green: 71/255, blue: 1/255))
                                    .padding(6)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)


                // MARK: Next Rank Preview
                VStack(spacing: 12) {
                    if currentRankId < ranks.count {
                        Text("Next Rank Preview")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 10) {
                            Image(systemName: ranks[currentRankId].emblemName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 236/255, green: 71/255, blue: 1/255),
                                            Color(red: 84/255, green: 0/255, blue: 232/255)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text(ranks[currentRankId].name.uppercased())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .background(Color.black)
            .ignoresSafeArea()
            .onAppear {
                glowPulse = true
            }
        }
    }
}

// MARK: - Preview

struct RankDetails_Previews: PreviewProvider {
    static var previews: some View {
        RankDetails()
    }
}
