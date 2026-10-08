import SwiftUI
import Charts
import FirebaseAuth
import FirebaseFirestore

struct TrendsView: View {

    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @Environment(ProStore.self) private var proStore
    @State private var listener: ListenerRegistration?
    @State private var currentXP: Int = 0
    @State private var streak: Int = 0
    @State private var longestStreak: Int = 0
    @State private var skillsData: [String: [String: Int]] = [:]
    @State private var dailyLogs: [DailyLog] = []
    @State private var monthlySummaries: [String: MonthlySummary] = [:]
    @State private var achievements: [Achievement] = []
    @State private var isLoading = true
    @State private var animateBars = false
    @State private var selectedRange: RangeOption = .week
    @State private var todayXP: Int = 0
    @State private var todayCompletedCount: Int = 0
    @State private var todayTotalPossibleXP: Int = 0
    @State private var todaySkillXPData: [String: Int] = [:]
    @State private var showPaywall = false

    enum RangeOption: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
        case allTime = "ALL"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .allTime: return 0
            }
        }

        var axisStride: Int {
            switch self {
            case .week: return 1
            case .month: return 7
            case .quarter: return 20
            case .allTime: return 1
            }
        }

        var isProOnly: Bool { self == .allTime }
    }

    // MARK: - Derived Data

    private var currentRank: Rank? {
        ranks.last(where: { $0.requiredXP <= Double(currentXP) })
    }

    private var nextRank: Rank? {
        ranks.first(where: { $0.requiredXP > Double(currentXP) })
    }

    private var rankProgress: Double {
        guard let current = currentRank, let next = nextRank else { return 1.0 }
        let range = next.requiredXP - current.requiredXP
        guard range > 0 else { return 1.0 }
        return min(max((Double(currentXP) - current.requiredXP) / range, 0.0), 1.0)
    }

    /// Full-history roll-up (pruned monthly summaries + retained daily logs).
    private var allTimeStats: AllTimeStats {
        ProHistoryAggregator.allTimeStats(dailyLogs: dailyLogs, summaries: monthlySummaries)
    }

    private var rangeLogs: [DailyLog] {
        let calendar = Calendar.current
        let days = selectedRange.days
        let startOfToday = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else { return [] }
        let todayStr = isoDateString(from: Date())

        var result: [DailyLog] = []
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: i, to: start) else { continue }
            let dateStr = isoDateString(from: date)

            if dateStr == todayStr {
                result.append(DailyLog(
                    date: dateStr,
                    completedCount: todayCompletedCount,
                    xpGained: todayXP,
                    skillXP: todaySkillXPData,
                    streak: streak,
                    totalPossibleXP: todayTotalPossibleXP
                ))
            } else if let existing = dailyLogs.first(where: { $0.date == dateStr }) {
                result.append(existing)
            } else {
                result.append(DailyLog(
                    date: dateStr,
                    completedCount: 0,
                    xpGained: 0,
                    skillXP: [:],
                    streak: 0,
                    totalPossibleXP: 0
                ))
            }
        }
        return result
    }

    private var trendPoints: [TrendPoint] {
        rangeLogs.compactMap { log in
            guard let date = dateFromISO(log.date) else { return nil }
            return TrendPoint(
                id: date,
                date: date,
                xpGained: log.xpGained,
                completedCount: log.completedCount,
                totalPossible: log.totalPossibleXP
            )
        }
    }

    private var skillGains: [(skill: String, xp: Int)] {
        var totals: [String: Int] = [:]
        for log in rangeLogs {
            for (key, value) in log.skillXP {
                totals[key, default: 0] += value
            }
        }
        return totals
            .filter { $0.value > 0 }
            .map { ($0.key, $0.value) }
            .sorted { $0.xp > $1.xp }
    }

    private var thisWeekRate: Double { rateFor(days: 7, offset: 0) }
    private var lastWeekRate: Double { rateFor(days: 7, offset: 7) }

    private func rateFor(days: Int, offset: Int) -> Double {
        let points = trendPoints
        guard points.count >= offset else { return 0 }
        let slice = points.dropFirst(max(0, points.count - offset - days)).prefix(days)
        let done = slice.reduce(0) { $0 + $1.xpGained }
        let total = slice.reduce(0) { $0 + $1.totalPossible }
        return total > 0 ? Double(done) / Double(total) : 0
    }

    private var mostActiveWeekday: (String, Int)? {
        var counts: [Int: Int] = [:]
        for log in rangeLogs where log.completedCount > 0 {
            if let date = dateFromISO(log.date) {
                let weekday = Calendar.current.component(.weekday, from: date)
                counts[weekday, default: 0] += 1
            }
        }
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        return (weekdayName(best.key), best.value)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return names[safe: weekday] ?? ""
    }

    private var totalXPGained: Int {
        trendPoints.reduce(0) { $0 + $1.xpGained }
    }

    private var averageDailyXP: Int {
        guard !trendPoints.isEmpty else { return 0 }
        return totalXPGained / trendPoints.count
    }

    private var periodCompletionRate: Double {
        let done = trendPoints.reduce(0) { $0 + $1.xpGained }
        let total = trendPoints.reduce(0) { $0 + $1.totalPossible }
        return total > 0 ? min(Double(done) / Double(total), 1) : 0
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Header()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 60)
                } else {
                    rangeSelector
                        .opacity(animateBars ? 1 : 0)
                        .offset(y: animateBars ? 0 : 12)
                        .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.0) : nil, value: animateBars)

                    if selectedRange == .allTime {
                        if proStore.isPro {
                            allTimeStatsSection
                                .opacity(animateBars ? 1 : 0)
                                .offset(y: animateBars ? 0 : 12)
                                .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.05) : nil, value: animateBars)

                            allTimeChartSection
                                .opacity(animateBars ? 1 : 0)
                                .offset(y: animateBars ? 0 : 12)
                                .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.1) : nil, value: animateBars)
                        } else {
                            lockedAllTimeSection
                                .opacity(animateBars ? 1 : 0)
                                .offset(y: animateBars ? 0 : 12)
                                .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.05) : nil, value: animateBars)
                        }
                    } else {
                        xpChartSection
                            .opacity(animateBars ? 1 : 0)
                            .offset(y: animateBars ? 0 : 12)
                            .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.05) : nil, value: animateBars)

                        completionChartSection
                            .opacity(animateBars ? 1 : 0)
                            .offset(y: animateBars ? 0 : 12)
                            .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.1) : nil, value: animateBars)

                        skillGrowthSection
                            .opacity(animateBars ? 1 : 0)
                            .offset(y: animateBars ? 0 : 12)
                            .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.15) : nil, value: animateBars)

                        milestonesSection
                            .opacity(animateBars ? 1 : 0)
                            .offset(y: animateBars ? 0 : 12)
                            .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.2) : nil, value: animateBars)

                        insightsSection
                            .opacity(animateBars ? 1 : 0)
                            .offset(y: animateBars ? 0 : 12)
                            .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.25) : nil, value: animateBars)
                    }

                    Spacer(minLength: 40)
                }
            }
            .onAppear {
                fetchUserData()
            }
            .onDisappear {
                listener?.remove()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Range Selector

    private var rangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(RangeOption.allCases, id: \.self) { option in
                let locked = option.isProOnly && !proStore.isPro
                Button {
                    if locked {
                        showPaywall = true
                    } else {
                        selectedRange = option
                    }
                } label: {
                    HStack(spacing: 4) {
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                        }
                        Text(option.rawValue)
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedRange == option ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedRange == option
                            ? Color.white.opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.isProOnly ? "All time range, Arise Pro" : "\(option.rawValue) range")
                .accessibilityHint(locked ? "Opens the Arise Pro upgrade" : "")
                .accessibilityAddTraits(selectedRange == option ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
    }

    // MARK: - XP Chart

    private var xpChartSection: some View {
        VStack(spacing: 10) {
            sectionTitle("XP Over Time")

            let avg = averageDailyXP

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(formatXP(Double(totalXPGained))) XP")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("avg \(formatXP(Double(avg)))/day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                Chart(trendPoints) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("XP", point.xpGained)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255).opacity(0.35),
                                Color(red: 236/255, green: 71/255, blue: 1/255).opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("XP", point.xpGained)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    if avg > 0 {
                        RuleMark(y: .value("Average", avg))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedRange.axisStride)) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(axisDayLabel(date))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel {
                            if let xp = value.as(Double.self) {
                                Text(compactXP(xp))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                }
                .frame(height: 170)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
        .padding(.horizontal)
    }

    // MARK: - Completion Chart

    private var completionChartSection: some View {
        VStack(spacing: 10) {
            sectionTitle("Completion Rate")

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(periodCompletionRate * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("of scheduled tasks completed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                Chart(trendPoints) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Completed", point.completionRate),
                        width: .ratio(0.55)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 36/255, green: 180/255, blue: 96/255),
                                Color(red: 46/255, green: 204/255, blue: 113/255)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(2)

                    RuleMark(y: .value("Goal", 1.0))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                .chartYScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedRange.axisStride)) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(axisDayLabel(date))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int(rate * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                }
                .frame(height: 170)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
        .padding(.horizontal)
    }

    // MARK: - Skill Growth

    private var skillGrowthSection: some View {
        VStack(spacing: 10) {
            sectionTitle("Skill Growth")

            if skillGains.isEmpty {
                emptyCard(message: "No XP earned in this period yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(skillGains.enumerated()), id: \.element.skill) { _, gain in
                        VStack(spacing: 6) {
                            HStack(spacing: 10) {
                                Image(systemName: skillIcons[gain.skill] ?? "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(LinearGradient.brand)
                                    .frame(width: 24)

                                Text(gain.skill)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("+\(gain.xp) XP")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(LinearGradient.brand)
                                        .frame(width: animateBars ? max(2, geo.size.width * gainFraction(gain.xp)) : 0)
                                }
                                .animation(animationsEnabled ? .spring(response: 0.6) : nil, value: animateBars)
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)

                        if gain.skill != skillGains.last?.skill {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 50)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }

    private func gainFraction(_ xp: Int) -> Double {
        let maxGain = skillGains.map { $0.xp }.max() ?? 1
        guard maxGain > 0 else { return 0 }
        return Double(xp) / Double(maxGain)
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(spacing: 10) {
            sectionTitle("Milestones")

            VStack(spacing: 0) {
                if let next = nextRank, let current = currentRank {
                    milestoneRow(
                        icon: "arrow.up.circle.fill",
                        iconColor: Color(red: 84/255, green: 0/255, blue: 232/255),
                        title: "Next Rank",
                        subtitle: "\(current.name) → \(next.name)",
                        progress: rankProgress,
                        detail: "\(formatXP(next.requiredXP - Double(currentXP))) XP to go"
                    )
                }

                if achievements.isEmpty {
                    milestoneRow(
                        icon: "trophy.fill",
                        iconColor: .yellow,
                        title: "Achievements",
                        subtitle: "No achievements yet",
                        progress: 0,
                        detail: "Keep going — they'll appear here."
                    )
                } else {
                    ForEach(achievements) { achievement in
                        milestoneRow(
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            title: achievement.title,
                            subtitle: achievement.unlockedDate ?? "",
                            progress: 1,
                            detail: achievement.description
                        )
                    }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func milestoneRow(icon: String, iconColor: Color, title: String, subtitle: String, progress: Double, detail: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(LinearGradient.brand)
                        .frame(width: animateBars ? max(2, geo.size.width * progress) : 0)
                }
                .animation(animationsEnabled ? .spring(response: 0.6) : nil, value: animateBars)
            }
            .frame(height: 6)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)

        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 50)
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(spacing: 10) {
            sectionTitle("Insights")

            VStack(spacing: 0) {
                insightRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "This week",
                    value: "\(Int(thisWeekRate * 100))% completed",
                    subtitle: "vs \(Int(lastWeekRate * 100))% last week"
                )

                if let active = mostActiveWeekday {
                    insightRow(
                        icon: "calendar",
                        color: Color(red: 84/255, green: 0/255, blue: 232/255),
                        title: "Most active",
                        value: active.0,
                        subtitle: "\(active.1) active day\(active.1 == 1 ? "" : "s") in this period"
                    )
                }

                insightRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "Longest streak",
                    value: "\(longestStreak) days",
                    subtitle: "Keep the chain alive."
                )
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private func insightRow(icon: String, color: Color, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - All Time (Pro)

    private var allTimeStatsSection: some View {
        VStack(spacing: 10) {
            sectionTitle("All Time")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                statCard(icon: "bolt.fill", value: formatXP(Double(allTimeStats.totalXP)), label: "Total XP")
                statCard(icon: "checkmark.circle.fill", value: formatXP(Double(allTimeStats.totalCompleted)), label: "Tasks completed")
                statCard(icon: "flame.fill", value: "\(allTimeStats.bestStreak) days", label: "Best streak")
                statCard(icon: "calendar", value: "\(allTimeStats.activeDays)", label: "Active days")
            }

            if let earliest = allTimeStats.earliestMonth {
                Text("History saved since \(monthLabel(earliest))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal)
    }

    private var allTimeChartSection: some View {
        VStack(spacing: 10) {
            sectionTitle("XP by Month")

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(allTimeStats.months.count) month\(allTimeStats.months.count == 1 ? "" : "s") tracked")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("\(Int(allTimeStats.completionRate * 100))% overall")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                Chart(allTimeStats.months) { month in
                    BarMark(
                        x: .value("Month", month.date, unit: .month),
                        y: .value("XP", month.xpGained),
                        width: .ratio(0.6)
                    )
                    .foregroundStyle(LinearGradient.brand)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(shortMonthLabel(date))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel {
                            if let xp = value.as(Double.self) {
                                Text(compactXP(xp))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                }
                .frame(height: 170)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
        .padding(.horizontal)
    }

    private var lockedAllTimeSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(LinearGradient.brand)
                .padding(.top, 6)

            Text("Unlock Your Full History")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Arise Pro keeps your monthly XP, completions, active days, and best streaks for as long as you use Arise — even after daily details are summarized.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let earliest = allTimeStats.earliestMonth {
                Text("History saved since \(monthLabel(earliest))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button {
                showPaywall = true
            } label: {
                Text("Unlock with Arise Pro")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(LinearGradient.brand))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .accessibilityHint("Opens the Arise Pro upgrade")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(LinearGradient.brand)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func monthLabel(_ month: String) -> String {
        guard let date = AriseDate.date(fromISO: "\(month)-01") else { return month }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    private func shortMonthLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    // MARK: - Shared UI

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func emptyCard(message: String) -> some View {
        HStack {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.3))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func axisDayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let today = Calendar.current.isDateInToday(date)
        if today { return "Today" }
        if selectedRange == .week {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return fmt.string(from: date)
        }
        return "\(month)/\(day)"
    }

    // MARK: - Data Fetching

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        let db = Firestore.firestore()

        listener = db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }

            self.currentXP = data["xp"] as? Int ?? 0
            self.streak = data["streak"] as? Int ?? 0
            self.longestStreak = data["longestStreak"] as? Int ?? 0
            if let rawSkills = data["skills"] as? [String: [String: Int]] {
                var recalculated: [String: [String: Int]] = [:]
                for (skill, values) in rawSkills {
                    let xp = values["xp"] ?? 0
                    let level = calculateSkillLevel(from: xp)
                    recalculated[skill] = ["xp": xp, "level": level]
                }
                self.skillsData = recalculated
            } else {
                self.skillsData = [:]
            }

            self.todayXP = (data["todaySkillXP"] as? [String: Int] ?? [:]).values.reduce(0, +)
            self.todayCompletedCount = (data["completedTasks"] as? [String])?.count ?? 0
            self.todayTotalPossibleXP = data["todayTotalPossibleXP"] as? Int ?? 0
            self.todaySkillXPData = data["todaySkillXP"] as? [String: Int] ?? [:]

            if let rawAchievements = data["achievements"] as? [String: [String: Any]] {
                var unlocked: [Achievement] = []
                for (indexStr, info) in rawAchievements {
                    guard let index = Int(indexStr),
                          let isUnlocked = info["unlocked"] as? Bool,
                          isUnlocked,
                          let base = allAchievements.first(where: { $0.index == index }) else { continue }
                    var achievement = base
                    achievement.unlocked = true
                    achievement.unlockedDate = info["unlockedDate"] as? String
                    unlocked.append(achievement)
                }
                self.achievements = unlocked.sorted { $0.index < $1.index }
            } else {
                self.achievements = []
            }

            if self.achievements.isEmpty {
                let skillXP: [String: Int] = skillsData.mapValues { $0["xp"] ?? 0 }
                let rankId = currentRank?.id ?? 1
                self.achievements = allAchievements.compactMap { base in
                    guard AchievementEngine.isUnlocked(base, totalXP: currentXP, currentRankId: rankId, skillXP: skillXP) else { return nil }
                    var a = base
                    a.unlocked = true
                    let fmt = DateFormatter()
                    fmt.dateFormat = "MMM yyyy"
                    fmt.locale = Locale(identifier: "en_US_POSIX")
                    a.unlockedDate = fmt.string(from: Date())
                    return a
                }
            }

            if let rawLogs = data["dailyLogs"] as? [String: [String: Any]] {
                var logs: [DailyLog] = []
                for (dateStr, entry) in rawLogs {
                    logs.append(DailyLog(
                        date: dateStr,
                        completedCount: entry["completedCount"] as? Int ?? 0,
                        xpGained: entry["xpGained"] as? Int ?? 0,
                        skillXP: entry["skillXP"] as? [String: Int] ?? [:],
                        streak: entry["streak"] as? Int ?? 0,
                        totalPossibleXP: entry["totalPossibleXP"] as? Int ?? 0
                    ))
                }
                self.dailyLogs = logs.sorted { $0.date < $1.date }
            } else {
                self.dailyLogs = []
            }

            self.monthlySummaries = ProHistoryAggregator.summaries(from: data["monthlySummaries"])

            self.isLoading = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.animateBars = true
            }
        }
    }

    // MARK: - Helpers

    private func dateFromISO(_ str: String) -> Date? {
        AriseDate.date(fromISO: str)
    }

    private func isoDateString(from date: Date) -> String {
        AriseDate.isoString(from: date)
    }

    private func formatXP(_ xp: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(xp))) ?? "\(Int(xp))"
    }

    private func compactXP(_ xp: Double) -> String {
        let value = Int(xp)
        if value >= 1000 {
            return String(format: "%.0fK", Double(value) / 1000.0)
        }
        return "\(value)"
    }
}

struct TrendPoint: Identifiable {
    let id: Date
    let date: Date
    let xpGained: Int
    let completedCount: Int
    let totalPossible: Int

    var completionRate: Double {
        guard totalPossible > 0 else { return 0 }
        return min(Double(xpGained) / Double(totalPossible), 1)
    }
}

// MARK: - Header

private struct Header: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Your Insights")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Trends in your effort over time")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 8)
        .padding(.horizontal)
    }
}
