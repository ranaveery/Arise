import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

//Ring works, three cards work, tasks completed today and radar chart don't work
struct TrendsView: View {
    
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var currentXP: Double = 0
    @State private var streak: Int = 0
    @State private var bestSkill: String = ""
    @State private var attentionSkill: String = ""
    @State private var tasksCompletedToday: Int = 0
    @State private var totalTasksToday: Int = 0
    @State private var skillProgress: [String: Double] = [:]
    @State private var skillLabels: [String] = []
    @State private var skillValues: [Double] = []

    private let xpGoal: Double = 20100.0
    
    var journeyProgress: Double {
        return min(currentXP / xpGoal, 1.0)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Header()

                // Journey Progress Ring replaces AverageGrowthCard
                JourneyProgressRing(
                    progress: journeyProgress,
                    currentXP: currentXP,
                    xpGoal: xpGoal,
                    animationsEnabled: animationsEnabled
                )
                .padding(.horizontal)


                // --- Streak, Best Skill, Attention ---
                HStack(spacing: 10) {
                    summaryCard(title: "Streak", value: "\(streak)", icon: "flame.fill", color: .orange)
                    summaryCard(title: "Best", value: bestSkill, icon: "crown.fill", color: .green)
                    summaryCard(title: "Weak", value: attentionSkill, icon: "exclamationmark.triangle.fill", color: .red)
                }
                .padding(.horizontal)

                VStack(alignment: .center, spacing: 8) {
                    Text("Skill Contributions")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)

                    SpiderChart(
                        values: skillValues,
                        labels: skillLabels,
                        steps: 4,
                        fillColor: Color.purple.opacity(0.28),
                        strokeColor: .purple,
                        animationsEnabled: animationsEnabled
                    )
                    .frame(height: 260)
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .onAppear {
                fetchUserData()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }

            self.currentXP = data["xp"] as? Double ?? 0
            self.streak = data["streak"] as? Int ?? 0

            // Extract skills
            if let skillsData = data["skills"] as? [String: [String: Int]] {
                // Best & lowest skill by raw xp
                let sorted = skillsData.sorted {
                    ($0.value["xp"] ?? 0) > ($1.value["xp"] ?? 0)
                }
                if let best = sorted.first?.key { self.bestSkill = best }
                if let lowest = sorted.last?.key { self.attentionSkill = lowest }

                // Build a map of progress (xp / 3350) clamped 0..1
                var progressDict: [String: Double] = [:]
                for (skill, info) in skillsData {
                    let xp = Double(info["xp"] ?? 0)
                    progressDict[skill] = min(max(xp / 3350.0, 0.0), 1.0)
                }
                self.skillProgress = progressDict // optional: keep for other uses

                // --- Build ordered arrays (guaranteed order) ---
                let orderedKeys = ["Discipline", "Fitness", "Fuel", "Network", "Resilience", "Wisdom"]
                var labels: [String] = []
                var values: [Double] = []
                for key in orderedKeys {
                    labels.append(key)
                    values.append(progressDict[key] ?? 0.0) // default 0 if missing
                }

                // Update state (atomic-ish)
                DispatchQueue.main.async {
                    self.skillLabels = labels
                    self.skillValues = values
                }
            } else {
                DispatchQueue.main.async {
                    self.bestSkill = "—"
                    self.attentionSkill = "—"
                    self.skillProgress = [:]
                    self.skillLabels = []
                    self.skillValues = []
                }
            }
        }
    }





    // --- Summary Card ---
    func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            Text(value.isEmpty ? "—" : value)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Header
private struct Header: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Your Insights")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("A glance at your balance and progress")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 40)
    }
}

private func skillProgress(for xp: Int) -> Double {
    let level = calculateSkillLevel(from: xp)
    let currentThreshold = skillLevelThresholds[level - 1]
    let nextThreshold = level < skillLevelThresholds.count
        ? skillLevelThresholds[level]
        : skillLevelThresholds.last!

    let range = nextThreshold - currentThreshold
    guard range > 0 else { return 1 }

    let progress = Double(xp - currentThreshold) / Double(range)
    return min(max(progress, 0), 1.0)
}

private func calculateSkillLevel(from xp: Int) -> Int {
    for (index, threshold) in skillLevelThresholds.enumerated().reversed() {
        if xp >= threshold {
            return index + 1
        }
    }
    return 1
}


//private struct JourneyProgressRing: View {
//    let progress: Double
//    let currentXP: Double
//    let xpGoal: Double
//    let animationsEnabled: Bool
//    @State private var animateProgress = false
//
//    var body: some View {
//        VStack(alignment: .center, spacing: 8) {
//            Text("Journey Progress")
//                .font(.headline)
//                .foregroundColor(.white.opacity(0.8))
//                .padding(.horizontal, 4)
//
//            ZStack {
//                Circle()
//                    .stroke(Color.white.opacity(0.1), lineWidth: 18)
//                    .frame(height: 180)
//
//                Circle()
//                    .trim(from: 0, to: animateProgress ? progress : 0)
//                    .stroke(
//                        AngularGradient(
//                            gradient: Gradient(colors: [
//                                Color(red: 84/255, green: 0/255, blue: 232/255),
//                                Color(red: 236/255, green: 71/255, blue: 1/255)
//                            ]),
//                            center: .center
//                        ),
//                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
//                    )
//                    .rotationEffect(.degrees(-90))
//                    .frame(height: 180)
//                    .animation(
//                        animationsEnabled ? .easeOut(duration: 0.8) : nil,
//                        value: animateProgress
//                    )
//
//                VStack {
//                    Text("\(Int(progress * 100))%")
//                        .font(.largeTitle.bold())
//                        .foregroundColor(.white)
//                    Text("\(Int(currentXP)) / \(Int(xpGoal)) XP")
//                        .font(.caption)
//                        .foregroundColor(.white.opacity(0.7))
//                }
//            }
//            .padding(.vertical, 12)
//            .onAppear {
//                if animationsEnabled {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                        animateProgress = true
//                    }
//                } else {
//                    animateProgress = true // instantly show full progress
//                }
//            }
//        }
//    }
//}
private struct JourneyProgressRing: View {
    let progress: Double
    let currentXP: Double
    let xpGoal: Double
    let animationsEnabled: Bool
    @State private var animateProgress = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Journey Progress")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 4)

            ZStack {
                // Background glow
                Circle()
                    .stroke(Color(red: 84/255, green: 0/255, blue: 232/255).opacity(0.3), lineWidth: 22)
                    .frame(height: 180)
                    .blur(radius: 10)

                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 18)
                    .frame(height: 180)

                // Progress ring (solid purple)
                Circle()
                    .trim(from: 0, to: animateProgress ? progress : 0)
                    .stroke(
                        Color(.purple),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(height: 180)
                    .shadow(color: Color(red: 84/255, green: 0/255, blue: 232/255).opacity(0.4),
                            radius: 8, x: 0, y: 0)
                    .animation(
                        animationsEnabled ? .easeOut(duration: 0.8) : nil,
                        value: animateProgress
                    )

                // Center text
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Text("\(Int(currentXP)) / \(Int(xpGoal)) XP")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.vertical, 12)
            .onAppear {
                if animationsEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        animateProgress = true
                    }
                } else {
                    animateProgress = true
                }
            }
        }
    }
}



// MARK: - Spider (Radar) Chart

struct SpiderChart: View {
    let values: [Double]
    let labels: [String]
    let steps: Int
    let fillColor: Color
    let strokeColor: Color
    let animationsEnabled: Bool
    @State private var animProgress: CGFloat = 0.0

    private var normalizedValues: [CGFloat] {
        return values.map { CGFloat(min(max($0, 0.0), 1.0)) }
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let size = min(width, height)
            let radius = size * 0.4
            let center = CGPoint(x: width/2, y: height/2)
            let count = labels.count

            ZStack {
                ForEach(1...steps, id: \.self) { step in
                    PolygonGrid(count: count, fraction: CGFloat(step)/CGFloat(steps))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }

                ForEach(0..<count, id: \.self) { i in
                    Path { p in
                        p.move(to: center)
                        let angle = angleFor(index: i, total: count)
                        let point = pointOnCircle(center: center, radius: radius, angle: angle)
                        p.addLine(to: point)
                    }
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }

                RadarPolygon(values: normalizedValues.map { $0 * animProgress }, center: center, radius: radius)
                    .fill(fillColor)

                RadarPolygon(values: normalizedValues.map { $0 * animProgress }, center: center, radius: radius)
                    .stroke(strokeColor, lineWidth: 2)

                ForEach(Array(labels.enumerated()), id: \.offset) { item in
                    let i = item.offset
                    let label = item.element
                    let angle = angleFor(index: i, total: count)
                    let pos = pointOnCircle(center: center, radius: radius + 18, angle: angle)
                    Text(label).font(.caption).foregroundColor(.white).position(pos)
                }
            }
            .onAppear {
                if animationsEnabled {
                    withAnimation(.easeOut(duration: 0.6)) {
                        animProgress = 1.0
                    }
                } else {
                    animProgress = 1.0
                }
            }
        }
    }
}

private struct PolygonGrid: Shape {
    let count: Int
    let fraction: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.4 * fraction
        guard count > 2 else { return path }
        for i in 0..<count {
            let angle = angleFor(index: i, total: count)
            let point = pointOnCircle(center: center, radius: radius, angle: angle)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

private struct RadarPolygon: Shape {
    let values: [CGFloat]
    let center: CGPoint
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 2 else { return path }
        for i in 0..<values.count {
            let angle = angleFor(index: i, total: values.count)
            let r = radius * values[i]
            let point = pointOnCircle(center: center, radius: r, angle: angle)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Math Helpers

@inline(__always)
private func angleFor(index: Int, total: Int) -> CGFloat {
    let fraction = CGFloat(index) / CGFloat(max(total, 1))
    return fraction * 2.0 * .pi - (.pi / 2.0)
}

@inline(__always)
private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
    CGPoint(x: center.x + CGFloat(cos(Double(angle))) * radius,
            y: center.y + CGFloat(sin(Double(angle))) * radius)
}
