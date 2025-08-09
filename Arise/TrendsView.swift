import SwiftUI

struct TrendsView: View {
    struct SkillTrend: Identifiable {
        let id = UUID()
        let name: String
        let trendPercent: Double
        let recentData: [Double]
    }

    let skillTrends = [
        SkillTrend(name: "Resilience", trendPercent: 3.2, recentData: [1, 2, 3, 2, 4, 5, 6]),
        SkillTrend(name: "Fuel", trendPercent: -1.8, recentData: [5, 4, 4, 3, 3, 2, 1]),
        SkillTrend(name: "Fitness", trendPercent: 7.5, recentData: [2, 3, 5, 6, 7, 8, 10]),
        SkillTrend(name: "Wisdom", trendPercent: 0.5, recentData: [1, 1, 2, 2, 3, 3, 4]),
        SkillTrend(name: "Discipline", trendPercent: 2.3, recentData: [3, 3, 4, 5, 5, 6, 7]),
        SkillTrend(name: "Network", trendPercent: -0.2, recentData: [4, 4, 3, 3, 3, 2, 2])
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
                VStack(spacing: 4) {
                    Text("Skill Trends")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Track your growth over time")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)

                // Average Growth Chart
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

                        MiniSparkline(data: averageGrowth)
                            .frame(height: 150)
                            .padding(.horizontal)
                    }
                }

                // Summary Cards
                HStack(spacing: 10) {
                    summaryCard(title: "Overall", value: "+3.1%", icon: "chart.line.uptrend.xyaxis", color: .green)
                    summaryCard(title: "Best Skill", value: "Fitness", icon: "flame.fill", color: .orange)
                    summaryCard(title: "Attention", value: "Fuel", icon: "exclamationmark.triangle.fill", color: .red)
                }
                .padding(.horizontal)

                // Skill Trends
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

                            HStack(spacing: 4) {
                                Image(systemName: skill.trendPercent >= 0 ? "arrow.up" : "arrow.down")
                                    .foregroundColor(skill.trendPercent >= 0 ? .green : .red)
                                Text(String(format: "%.1f%%", skill.trendPercent))
                                    .foregroundColor(skill.trendPercent >= 0 ? .green : .red)
                            }
                            .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)

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

struct MiniSparkline: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geo in
            let maxVal = (data.max() ?? 1)
            let minVal = (data.min() ?? 0)
            let range = maxVal - minVal == 0 ? 1 : maxVal - minVal

            Path { path in
                for index in data.indices {
                    let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = geo.size.height * (1 - CGFloat((data[index] - minVal) / range))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.purple, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}
