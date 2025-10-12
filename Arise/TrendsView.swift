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

    struct SkillTrend: Identifiable {
        let id = UUID()
        let name: String
        let trendPercent: Double
        let recentData: [Double]
    }

    // Dummy radar data (still shown)
    let skillTrends = [
        SkillTrend(name: "Resilience", trendPercent: 6.2, recentData: [1, 2, 3, 2, 4, 5, 6]),
        SkillTrend(name: "Fuel", trendPercent: 3.8, recentData: [5, 4, 4, 3, 3, 2, 1]),
        SkillTrend(name: "Fitness", trendPercent: 7.5, recentData: [2, 3, 5, 6, 7, 8, 10]),
        SkillTrend(name: "Wisdom", trendPercent: 5.5, recentData: [1, 1, 2, 2, 3, 3, 4]),
        SkillTrend(name: "Discipline", trendPercent: 8.3, recentData: [3, 3, 4, 5, 5, 6, 7]),
        SkillTrend(name: "Network", trendPercent: 8.2, recentData: [4, 4, 3, 3, 3, 2, 2])
    ]
    
    private let xpGoal: Double = 20100.0
    
    var journeyProgress: Double {
        return min(currentXP / xpGoal, 1.0)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Header()

                // Journey Progress Ring replaces AverageGrowthCard
                JourneyProgressRing(progress: journeyProgress, currentXP: currentXP, xpGoal: xpGoal)
                    .padding(.horizontal)

                // --- Streak, Best Skill, Attention ---
                HStack(spacing: 10) {
                    summaryCard(title: "Streak", value: "\(streak)", icon: "flame.fill", color: .orange)
                    summaryCard(title: "Best Skill", value: bestSkill, icon: "medal.fill", color: .green)
                    summaryCard(title: "Attention", value: attentionSkill, icon: "exclamationmark.triangle.fill", color: .red)
                }
                .padding(.horizontal)

                // --- Replace Skill Trend List with Task Progress Today ---
                TaskProgressCard(completed: tasksCompletedToday, total: totalTasksToday)
                    .padding(.horizontal)

                // --- Keep Skill Growth Radar ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Growth Radar")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)

                    SpiderChart(
                        values: skillTrends.map { max(0, $0.trendPercent) },
                        labels: skillTrends.map { $0.name },
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
                fetchTaskData()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // --- Firestore Fetch ---
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            
            self.currentXP = data["xp"] as? Double ?? 0
            self.streak = data["streak"] as? Int ?? 0

            // Extract skills
            if let skillsData = data["skills"] as? [String: [String: Int]] {
                // Sort by XP descending
                let sorted = skillsData.sorted {
                    ($0.value["xp"] ?? 0) > ($1.value["xp"] ?? 0)
                }

                if let best = sorted.first?.key {
                    self.bestSkill = best
                }

                if let lowest = sorted.last?.key {
                    self.attentionSkill = lowest
                }
            } else {
                self.bestSkill = "—"
                self.attentionSkill = "—"
            }
        }
    }


    private func fetchTaskData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let today = Calendar.current.startOfDay(for: Date())

        db.collection("users").document(uid).collection("tasks")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else { return }
                let total = docs.count
                let completed = docs.filter { $0.data()["completed"] as? Bool == true }.count
                self.tasksCompletedToday = completed
                self.totalTasksToday = total
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
                .font(.title3.bold())
                .foregroundColor(.white)
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

// MARK: - Journey Progress Ring
private struct JourneyProgressRing: View {
    let progress: Double
    let currentXP: Double
    let xpGoal: Double
    @State private var animateProgress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journey Progress")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 4)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 18)
                    .frame(height: 180)

                Circle()
                    .trim(from: 0, to: animateProgress ? progress : 0)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(height: 180)
                    .animation(.easeOut(duration: 0.8), value: animateProgress)

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateProgress = true
                }
            }
        }
    }
}

// MARK: - Task Progress Card
private struct TaskProgressCard: View {
    let completed: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks Completed Today")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 4)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 100)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(completed) / \(total)")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Text("completed")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    if total > 0 {
                        let ratio = Double(completed) / Double(total)
                        Circle()
                            .trim(from: 0, to: ratio)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 84/255, green: 0/255, blue: 232/255),
                                        Color(red: 236/255, green: 71/255, blue: 1/255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 70, height: 70)
                            .padding(.trailing, 24)
                    }
                }
                .padding(.horizontal, 24)
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
        let maxVal = max(values.max() ?? 1.0, 0.000001)
        return values.map { v in CGFloat(max(0.0, v) / maxVal) }
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
