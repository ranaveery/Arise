import SwiftUI

struct FitnessView: View {
    var body: some View {
        Text("Fitness Details").foregroundColor(.white).background(Color.black)
    }
}
//
//Okay here are the things I have in my insights page right now and what I want you to replace them with:
//
//Average skill growth chart should be replaced with journey progress percentage ring (user's current XP/20100)
//Streak,Best skill, attention HStack should not be replaced, keep it there.
//Skill trend list should be replaced with how many tasks/ total tasks have been completed today
//Skill growth radar should not be replaced, keep it there.
//
//Give me the entire file code with the changes made and don't change the design and colors of stuff, don't cut corners. Fetch the required data from firestore and replace the hard coded things like the streak, best skill and attention to firestore based
//
//Here's the code you have to edit:
//import SwiftUI
//import Firebase
//import FirebaseAuth
//import FirebaseFirestore
//
//struct TrendsView: View {
//    
//    @AppStorage("animationsEnabled") private var animationsEnabled = true
//
//    struct SkillTrend: Identifiable {
//        let id = UUID()
//        let name: String
//        let trendPercent: Double
//        let recentData: [Double]
//    }
//
//    let skillTrends = [
//        SkillTrend(name: "Resilience", trendPercent: 6.2, recentData: [1, 2, 3, 2, 4, 5, 6]),
//        SkillTrend(name: "Fuel", trendPercent: 3.8, recentData: [5, 4, 4, 3, 3, 2, 1]),
//        SkillTrend(name: "Fitness", trendPercent: 7.5, recentData: [2, 3, 5, 6, 7, 8, 10]),
//        SkillTrend(name: "Wisdom", trendPercent: 5.5, recentData: [1, 1, 2, 2, 3, 3, 4]),
//        SkillTrend(name: "Discipline", trendPercent: 8.3, recentData: [3, 3, 4, 5, 5, 6, 7]),
//        SkillTrend(name: "Network", trendPercent: 8.2, recentData: [4, 4, 3, 3, 3, 2, 2])
//    ]
//
//    var averageGrowth: [Double] {
//        let count = skillTrends.first?.recentData.count ?? 0
//        guard count > 0 else { return [] }
//        return (0..<count).map { i in
//            let total = skillTrends.map { $0.recentData[i] }.reduce(0, +)
//            return total / Double(skillTrends.count)
//        }
//    }
//
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            VStack(spacing: 24) {
//                Header()
//
//                AverageGrowthCard(data: averageGrowth, animationsEnabled: animationsEnabled)
//
//                HStack(spacing: 10) {
//                    summaryCard(title: "Streak", value: "4", icon: "flame.fill", color: .orange)
//                    summaryCard(title: "Best Skill", value: "Fitness", icon: "medal.fill", color: .green)
//                    summaryCard(title: "Attention", value: "Fuel", icon: "exclamationmark.triangle.fill", color: .red)
//                }
//                .padding(.horizontal)
//
//                SkillTrendList(skillTrends: skillTrends, animationsEnabled: animationsEnabled)
//
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Skill Growth Radar")
//                        .font(.headline)
//                        .foregroundColor(.white.opacity(0.8))
//                        .padding(.horizontal)
//
//                    SpiderChart(
//                        values: skillTrends.map { max(0, $0.trendPercent) },
//                        labels: skillTrends.map { $0.name },
//                        steps: 4,
//                        fillColor: Color.purple.opacity(0.28),
//                        strokeColor: .purple,
//                        animationsEnabled: animationsEnabled
//                    )
//                    .frame(height: 260)
//                    .padding(.horizontal)
//                }
//
//                Spacer(minLength: 40)
//            }
//        }
//        .background(Color.black.ignoresSafeArea())
//    }
//
//    func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
//        VStack(spacing: 8) {
//            HStack {
//                Image(systemName: icon).foregroundColor(color)
//                Text(title).foregroundColor(.white.opacity(0.7)).font(.caption)
//            }
//            Text(value).font(.title3.bold()).foregroundColor(.white)
//        }
//        .padding()
//        .frame(maxWidth: .infinity)
//        .background(Color.white.opacity(0.05))
//        .cornerRadius(12)
//    }
//}
//
//private struct Header: View {
//    var body: some View {
//        VStack(spacing: 4) {
//            Text("Your Insights")
//                .font(.largeTitle.bold())
//                .foregroundColor(.white)
//            Text("A glance at your balance and progress")
//                .font(.subheadline)
//                .foregroundColor(.white.opacity(0.7))
//        }
//        .padding(.top, 40)
//    }
//}
//
//private struct AverageGrowthCard: View {
//    let data: [Double]
//    let animationsEnabled: Bool
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Average Skill Growth")
//                .font(.headline)
//                .foregroundColor(.white.opacity(0.8))
//                .padding(.horizontal)
//            ZStack {
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(Color.white.opacity(0.05))
//                    .frame(height: 180)
//                    .padding(.horizontal)
//                MiniSparkline(data: data, animationsEnabled: animationsEnabled)
//                    .frame(height: 150)
//                    .padding(.horizontal)
//            }
//        }
//    }
//}
//
//private struct SkillTrendList: View {
//    let skillTrends: [TrendsView.SkillTrend]
//    let animationsEnabled: Bool
//
//    var body: some View {
//        VStack(spacing: 20) {
//            ForEach(skillTrends) { skill in
//                HStack {
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text(skill.name).font(.headline).foregroundColor(.white)
//                        MiniSparkline(data: skill.recentData, animationsEnabled: animationsEnabled)
//                            .frame(height: 30)
//                    }
//                    Spacer()
//                    let isUp: Bool = skill.trendPercent >= 0
//                    HStack(spacing: 4) {
//                        Image(systemName: isUp ? "arrow.up" : "arrow.down")
//                            .foregroundColor(isUp ? .green : .red)
//                        Text(String(format: "%.1f%%", skill.trendPercent))
//                            .foregroundColor(isUp ? .green : .red)
//                    }.font(.headline)
//                }
//                .padding(.horizontal)
//            }
//        }
//        .padding(.vertical)
//    }
//}
//
//// MARK: - Mini Sparkline
//
//struct MiniSparkline: View {
//    let data: [Double]
//    let animationsEnabled: Bool
//    @State private var animationProgress: CGFloat = 0.0
//
//    var body: some View {
//        GeometryReader { geo in
//            let width = geo.size.width
//            let height = geo.size.height
//            let maxVal = (data.max() ?? 1)
//            let minVal = (data.min() ?? 0)
//            let range = (maxVal - minVal == 0) ? 1 : (maxVal - minVal)
//
//            Path { path in
//                for index in data.indices {
//                    let progress = CGFloat(index) / CGFloat(max(data.count - 1, 1))
//                    let x = width * progress
//                    let normalized = (data[index] - minVal) / range
//                    let y = height * (1 - CGFloat(normalized))
//                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
//                    else { path.addLine(to: CGPoint(x: x, y: y)) }
//                }
//            }
//            .trim(from: 0, to: animationProgress)
//            .stroke(
//                LinearGradient(
//                    colors: [
//                        Color(red: 84/255, green: 0/255, blue: 232/255),
//                        Color(red: 236/255, green: 71/255, blue: 1/255)
//                    ],
//                    startPoint: .leading,
//                    endPoint: .trailing
//                ),
//                lineWidth: 2
//            )
//            .onAppear {
//                if animationsEnabled {
//                    withAnimation(.easeOut(duration: 0.45)) {
//                        animationProgress = 1.0
//                    }
//                } else {
//                    animationProgress = 1.0
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Spider (Radar) Chart
//
//struct SpiderChart: View {
//    let values: [Double]
//    let labels: [String]
//    let steps: Int
//    let fillColor: Color
//    let strokeColor: Color
//    let animationsEnabled: Bool
//    @State private var animProgress: CGFloat = 0.0
//
//    private var normalizedValues: [CGFloat] {
//        let maxVal = max(values.max() ?? 1.0, 0.000001)
//        return values.map { v in CGFloat(max(0.0, v) / maxVal) }
//    }
//
//    var body: some View {
//        GeometryReader { proxy in
//            let width = proxy.size.width
//            let height = proxy.size.height
//            let size = min(width, height)
//            let radius = size * 0.4
//            let center = CGPoint(x: width/2, y: height/2)
//            let count = labels.count
//
//            ZStack {
//                ForEach(1...steps, id: \.self) { step in
//                    PolygonGrid(count: count, fraction: CGFloat(step)/CGFloat(steps))
//                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                }
//
//                ForEach(0..<count, id: \.self) { i in
//                    Path { p in
//                        p.move(to: center)
//                        let angle = angleFor(index: i, total: count)
//                        let point = pointOnCircle(center: center, radius: radius, angle: angle)
//                        p.addLine(to: point)
//                    }
//                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
//                }
//
//                RadarPolygon(values: normalizedValues.map { $0 * animProgress }, center: center, radius: radius)
//                    .fill(fillColor)
//
//                RadarPolygon(values: normalizedValues.map { $0 * animProgress }, center: center, radius: radius)
//                    .stroke(strokeColor, lineWidth: 2)
//
//                ForEach(Array(labels.enumerated()), id: \.offset) { item in
//                    let i = item.offset
//                    let label = item.element
//                    let angle = angleFor(index: i, total: count)
//                    let pos = pointOnCircle(center: center, radius: radius + 18, angle: angle)
//                    Text(label).font(.caption).foregroundColor(.white).position(pos)
//                }
//            }
//            .onAppear {
//                if animationsEnabled {
//                    withAnimation(.easeOut(duration: 0.6)) {
//                        animProgress = 1.0
//                    }
//                } else {
//                    animProgress = 1.0
//                }
//            }
//        }
//    }
//}
//
//private struct PolygonGrid: Shape {
//    let count: Int
//    let fraction: CGFloat
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let center = CGPoint(x: rect.midX, y: rect.midY)
//        let radius = min(rect.width, rect.height) * 0.4 * fraction
//        guard count > 2 else { return path }
//        for i in 0..<count {
//            let angle = angleFor(index: i, total: count)
//            let point = pointOnCircle(center: center, radius: radius, angle: angle)
//            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
//        }
//        path.closeSubpath()
//        return path
//    }
//}
//
//private struct RadarPolygon: Shape {
//    let values: [CGFloat]
//    let center: CGPoint
//    let radius: CGFloat
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        guard values.count > 2 else { return path }
//        for i in 0..<values.count {
//            let angle = angleFor(index: i, total: values.count)
//            let r = radius * values[i]
//            let point = pointOnCircle(center: center, radius: r, angle: angle)
//            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
//        }
//        path.closeSubpath()
//        return path
//    }
//}
//
//// MARK: - Math Helpers
//
//@inline(__always)
//private func angleFor(index: Int, total: Int) -> CGFloat {
//    let fraction = CGFloat(index) / CGFloat(max(total, 1))
//    return fraction * 2.0 * .pi - (.pi / 2.0)
//}
//
//@inline(__always)
//private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
//    CGPoint(x: center.x + CGFloat(cos(Double(angle))) * radius,
//            y: center.y + CGFloat(sin(Double(angle))) * radius)
//}
