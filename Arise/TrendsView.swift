import SwiftUI

struct TrendsView: View {
    struct SkillTrend: Identifiable {
        let id = UUID()
        let name: String
        let trendPercent: Double
        let recentData: [Double]
    }

    let skillTrends = [
        SkillTrend(name: "Resilience", trendPercent: 6.2, recentData: [1, 2, 3, 2, 4, 5, 6]),
        SkillTrend(name: "Fuel", trendPercent: 3.8, recentData: [5, 4, 4, 3, 3, 2, 1]),
        SkillTrend(name: "Fitness", trendPercent: 7.5, recentData: [2, 3, 5, 6, 7, 8, 10]),
        SkillTrend(name: "Wisdom", trendPercent: 5.5, recentData: [1, 1, 2, 2, 3, 3, 4]),
        SkillTrend(name: "Discipline", trendPercent: 8.3, recentData: [3, 3, 4, 5, 5, 6, 7]),
        SkillTrend(name: "Network", trendPercent: 8.2, recentData: [4, 4, 3, 3, 3, 2, 2])
    ]

    var averageGrowth: [Double] {
        let count = skillTrends.first?.recentData.count ?? 0
        guard count > 0 else { return [] }

        return (0..<count).map { i in
            let total = skillTrends.map { $0.recentData[i] }.reduce(0, +)
            return total / Double(skillTrends.count)
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                Header()

                // Average Growth Chart
                AverageGrowthCard(data: averageGrowth)

                // Summary Cards
                HStack(spacing: 10) {
                    summaryCard(title: "Overall", value: "+3.1%", icon: "chart.line.uptrend.xyaxis", color: .green)
                    summaryCard(title: "Best Skill", value: "Fitness", icon: "flame.fill", color: .orange)
                    summaryCard(title: "Attention", value: "Fuel", icon: "exclamationmark.triangle.fill", color: .red)
                }
                .padding(.horizontal)

                // Skill Trends
                SkillTrendList(skillTrends: skillTrends)

                // Spider Chart (Radar)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Growth Radar")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)

                    // Clamp negatives to zero to reflect "how much grew"
                    SpiderChart(
                        values: skillTrends.map { max(0, $0.trendPercent) },
                        labels: skillTrends.map { $0.name },
                        steps: 4,
                        fillColor: Color.purple.opacity(0.28),
                        strokeColor: .purple
                    )
                    .frame(height: 260)
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // Summary card view
    func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Subviews broken out to help the type-checker

private struct Header: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Skill Trends")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text("Track your growth over time")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 40)
    }
}

private struct AverageGrowthCard: View {
    let data: [Double]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Skill Growth")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 180)
                    .padding(.horizontal)

                MiniSparkline(data: data)
                    .frame(height: 150)
                    .padding(.horizontal)
            }
        }
    }
}

private struct SkillTrendList: View {
    let skillTrends: [TrendsView.SkillTrend]
    var body: some View {
        VStack(spacing: 20) {
            ForEach(skillTrends) { skill in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(skill.name)
                            .font(.headline)
                            .foregroundColor(.white)

                        MiniSparkline(data: skill.recentData)
                            .frame(height: 30)
                    }

                    Spacer()

                    let isUp: Bool = skill.trendPercent >= 0
                    HStack(spacing: 4) {
                        Image(systemName: isUp ? "arrow.up" : "arrow.down")
                            .foregroundColor(isUp ? .green : .red)
                        Text(String(format: "%.1f%%", skill.trendPercent))
                            .foregroundColor(isUp ? .green : .red)
                    }
                    .font(.headline)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let data: [Double]
    @State private var animationProgress: CGFloat = 0.0

    var body: some View {
        GeometryReader { geo in
            let width: CGFloat = geo.size.width
            let height: CGFloat = geo.size.height
            let maxVal: Double = (data.max() ?? 1)
            let minVal: Double = (data.min() ?? 0)
            let range: Double = (maxVal - minVal == 0) ? 1 : (maxVal - minVal)

            Path { path in
                for index in data.indices {
                    let progress: CGFloat = CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let x: CGFloat = width * progress
                    let normalized: Double = (data[index] - minVal) / range
                    let y: CGFloat = height * (1 - CGFloat(normalized))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .trim(from: 0, to: animationProgress)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 84/255, green: 0/255, blue: 232/255),
                        Color(red: 236/255, green: 71/255, blue: 1/255)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}


// MARK: - Spider (Radar) Chart

struct SpiderChart: View {
    let values: [Double]        // raw values (we normalize internally)
    let labels: [String]
    let steps: Int
    let fillColor: Color
    let strokeColor: Color

    init(values: [Double],
         labels: [String],
         steps: Int = 4,
         fillColor: Color = Color.purple.opacity(0.28),
         strokeColor: Color = .purple) {
        self.values = values
        self.labels = labels
        self.steps = max(1, steps)
        self.fillColor = fillColor
        self.strokeColor = strokeColor
    }

    private var normalizedValues: [CGFloat] {
        let maxVal: Double = max(values.max() ?? 1.0, 0.000001)
        return values.map { v in CGFloat(max(0.0, v) / maxVal) }
    }

    var body: some View {
        GeometryReader { proxy in
            let width: CGFloat = proxy.size.width
            let height: CGFloat = proxy.size.height
            let size: CGFloat = min(width, height)
            let radius: CGFloat = size * 0.4
            let center: CGPoint = CGPoint(x: width / 2.0, y: height / 2.0)
            let count: Int = labels.count

            ZStack {
                // Concentric rings
                ForEach(1...steps, id: \.self) { step in
                    PolygonGrid(count: count, fraction: CGFloat(step) / CGFloat(steps))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }

                // Spokes
                ForEach(0..<count, id: \.self) { i in
                    Path { p in
                        p.move(to: center)
                        let angle: CGFloat = angleFor(index: i, total: count)
                        let point: CGPoint = pointOnCircle(center: center, radius: radius, angle: angle)
                        p.addLine(to: point)
                    }
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }

                // Data fill & stroke
                RadarPolygon(values: normalizedValues, center: center, radius: radius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.28)
                    )

                RadarPolygon(values: normalizedValues, center: center, radius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )


                // Labels
                ForEach(Array(labels.enumerated()), id: \.offset) { item in
                    let i: Int = item.offset
                    let label: String = item.element
                    let angle: CGFloat = angleFor(index: i, total: count)
                    let pos: CGPoint = pointOnCircle(center: center, radius: radius + 18, angle: angle)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .position(pos)
                }
            }
            .frame(width: width, height: height)
        }
    }
}

// MARK: - Shapes & Geometry Helpers

private struct PolygonGrid: Shape {
    let count: Int
    let fraction: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center: CGPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(rect.width, rect.height) * 0.4 * fraction

        guard count > 2 else { return path }

        for i in 0..<count {
            let angle: CGFloat = angleFor(index: i, total: count)
            let point: CGPoint = pointOnCircle(center: center, radius: radius, angle: angle)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct RadarPolygon: Shape {
    let values: [CGFloat]   // normalized 0...1
    let center: CGPoint
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count: Int = values.count
        guard count > 2 else { return path }

        for i in 0..<count {
            let angle: CGFloat = angleFor(index: i, total: count)
            let r: CGFloat = radius * values[i]
            let point: CGPoint = pointOnCircle(center: center, radius: r, angle: angle)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Math Utilities (avoid cos/sin ambiguity)

@inline(__always)
private func angleFor(index: Int, total: Int) -> CGFloat {
    // Start at -π/2 (top), go clockwise
    let fraction: CGFloat = CGFloat(index) / CGFloat(max(total, 1))
    let theta: CGFloat = fraction * 2.0 * .pi - (.pi / 2.0)
    return theta
}

@inline(__always)
private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
    // Explicit Double casts to avoid "Ambiguous use of 'cos'" with CGFloat
    let dx: CGFloat = CGFloat(cos(Double(angle))) * radius
    let dy: CGFloat = CGFloat(sin(Double(angle))) * radius
    return CGPoint(x: center.x + dx, y: center.y + dy)
}

