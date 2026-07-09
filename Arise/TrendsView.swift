import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TrendsView: View {

    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var listener: ListenerRegistration?
    @State private var currentXP: Int = 0
    @State private var streak: Int = 0
    @State private var longestStreak: Int = 0
    @State private var skillsData: [String: [String: Int]] = [:]
    @State private var dailyLogs: [DailyLog] = []
    @State private var isLoading = true
    @State private var todayXP: Int = 0
    @State private var todayCompletedCount: Int = 0
    @State private var todayTotalPossibleXP: Int = 0
    @State private var animateBars = false

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

    private var thisWeekLogs: [DailyLog] {
        dailyLogs.filter { isInCurrentWeek($0.date) }
    }

    private var weekDayLogs: [DailyLog] {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)

        let daysFromMonday: Int
        switch todayWeekday {
        case 1: daysFromMonday = -6
        case 2: daysFromMonday = 0
        case 3: daysFromMonday = -1
        case 4: daysFromMonday = -2
        case 5: daysFromMonday = -3
        case 6: daysFromMonday = -4
        case 7: daysFromMonday = -5
        default: daysFromMonday = 0
        }

        guard let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: today) else { return [] }
        let todayStr = isoDateString(from: today)

        var days: [DailyLog] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: monday) else { continue }
            let dateStr = isoDateString(from: date)

            if dateStr == todayStr {
                days.append(DailyLog(
                    date: dateStr,
                    completedCount: todayCompletedCount,
                    xpGained: todayXP,
                    skillXP: [:],
                    streak: streak,
                    totalPossibleXP: todayTotalPossibleXP
                ))
            } else if let existing = dailyLogs.first(where: { $0.date == dateStr }) {
                days.append(existing)
            } else {
                days.append(DailyLog(
                    date: dateStr,
                    completedCount: 0,
                    xpGained: 0,
                    skillXP: [:],
                    streak: 0,
                    totalPossibleXP: 0
                ))
            }
        }
        return days
    }

    private var weeklyXP: Int {
        thisWeekLogs.reduce(0) { $0 + $1.xpGained } + todayXP
    }

    private var daysActiveThisWeek: Int {
        (todayCompletedCount > 0 ? 1 : 0) + thisWeekLogs.filter { $0.completedCount > 0 }.count
    }

struct SkillRow: Identifiable {
        var id: String { name }
        let name: String
        let level: Int
        let xp: Int
        let progress: Double
        let nextThreshold: Int
    }

    private var skillRows: [SkillRow] {
        allSkillNames.compactMap { name in
            guard let info = skillsData[name] else {
                return SkillRow(name: name, level: 1, xp: 0, progress: 0, nextThreshold: skillLevelThresholds[1])
            }
            let xp = info["xp"] ?? 0
            let level = info["level"] ?? 1
            let safeLevel = min(level, skillLevelThresholds.count - 1)
            let nextThreshold = level < skillLevelThresholds.count ? skillLevelThresholds[safeLevel] : (skillLevelThresholds.last ?? 3350)
            let currentThreshold = skillLevelThresholds[safeLevel - 1]
            let range = nextThreshold - currentThreshold
            let progress = range > 0 ? Double(xp - currentThreshold) / Double(range) : 1.0
            return SkillRow(name: name, level: level, xp: xp, progress: min(max(progress, 0), 1), nextThreshold: nextThreshold)
        }
    }

    private var nearestLevelUp: SkillRow? {
        skillRows.filter { $0.level < 10 }.min(by: { $0.nextThreshold - $0.xp < $1.nextThreshold - $1.xp })
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
                    weeklySummaryStrip
                        .opacity(animateBars ? 1 : 0)
                        .offset(y: animateBars ? 0 : 12)
                        .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.0) : nil, value: animateBars)

                    insightCardsRow
                        .opacity(animateBars ? 1 : 0)
                        .offset(y: animateBars ? 0 : 12)
                        .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.05) : nil, value: animateBars)

                    weeklyBreakdownSection
                        .opacity(animateBars ? 1 : 0)
                        .offset(y: animateBars ? 0 : 12)
                        .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.1) : nil, value: animateBars)

                    skillProgressSection
                        .opacity(animateBars ? 1 : 0)
                        .offset(y: animateBars ? 0 : 12)
                        .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.15) : nil, value: animateBars)

                    milestonesSection
                        .opacity(animateBars ? 1 : 0)
                        .offset(y: animateBars ? 0 : 12)
                        .animation(animationsEnabled ? .easeOut(duration: 0.35).delay(0.2) : nil, value: animateBars)

                    Spacer(minLength: 40)
                }
            }
            .onAppear {
                fetchUserData()
                fetchDailyLogs()
            }
            .onDisappear {
                listener?.remove()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Weekly Summary Strip

    private var weeklySummaryStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 15))
                .foregroundStyle(LinearGradient.brand)

            Text("This Week")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Text("\(formatXP(Double(weeklyXP))) XP")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("·")
                .foregroundColor(.white.opacity(0.25))

            Text("\(daysActiveThisWeek)/7 days")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Insight Cards

    private var insightCardsRow: some View {
        HStack(spacing: 12) {
            insightCard(
                title: "Streak",
                value: "\(streak)",
                icon: "flame.fill",
                color: .orange,
                subtitle: "Best: \(longestStreak) days"
            )
            insightCard(
                title: "Rank",
                value: currentRank?.name ?? "—",
                icon: "crown.fill",
                color: Color(red: 84/255, green: 0/255, blue: 232/255),
                subtitle: "\(Int(rankProgress * 100))% to \(nextRank?.name ?? "max")"
            )
        }
        .padding(.horizontal)
    }

    private func insightCard(title: String, value: String, icon: String, color: Color, subtitle: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }

    // MARK: - Weekly Breakdown

    private var weeklyBreakdownSection: some View {
        VStack(spacing: 8) {
            Text("Daily Breakdown")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(weekDayLogs, id: \.date) { log in
                    dailyBreakdownRow(log: log)
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .padding(.horizontal)
    }

    private func dailyBreakdownRow(log: DailyLog) -> some View {
        let todayStr = isoDateString(from: Date())
        let isToday = log.date == todayStr
        let isFuture = (dateFromISO(log.date) ?? Date.distantPast) > Date()
        let hasData = log.totalPossibleXP > 0

        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .center, spacing: 1) {
                    Text(dayAbbreviation(from: log.date))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isToday ? .white : .white.opacity(0.7))
                    Text(shortDate(from: log.date))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(width: 38)

                if hasData || isToday {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                            let denom = CGFloat(max(log.totalPossibleXP, 1))
                            let proportion = min(CGFloat(log.xpGained) / denom, 1)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(LinearGradient.brand)
                                .frame(width: animateBars ? max(4, geo.size.width * proportion) : 0)
                        }
                        .animation(animationsEnabled ? .spring(response: 0.5) : nil, value: animateBars)
                    }
                    .frame(height: 12)

                    HStack(spacing: 4) {
                        Text("\(log.xpGained)/\(log.totalPossibleXP)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: true, vertical: false)
                        if log.streak > 0 {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(width: 70, alignment: .trailing)
                } else {
                    Text(isFuture ? "Upcoming" : "No data")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)

            if log.date != weekDayLogs.last?.date {
                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.leading, 50)
            }
        }
    }

    // MARK: - Skill Progress

    private var skillProgressSection: some View {
        VStack(spacing: 8) {
            Text("Skills")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(skillRows) { skill in
                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: skillIcons[skill.name] ?? "star.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(LinearGradient.brand)
                                .frame(width: 26)

                            Text(skill.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)

                            Spacer()

                            Text("LVL \(skill.level)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }

                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(LinearGradient.brand)
                                        .frame(width: animateBars ? max(2, geo.size.width * skill.progress) : 0)
                                }
                                .animation(animationsEnabled ? .spring(response: 0.6) : nil, value: animateBars)
                            }
                            .frame(height: 8)

                            Text("\(skill.xp)/\(skill.nextThreshold)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.35))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)

                    if skill.name != skillRows.last?.name {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(spacing: 8) {
            Text("Milestones")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                if let next = nextRank, let current = currentRank {
                    milestoneCard(
                        title: "Next Rank",
                        subtitle: current.name,
                        progress: rankProgress,
                        detail: "\(formatXP(next.requiredXP - Double(currentXP))) XP to \(next.name)",
                        icon: "arrow.up.circle.fill",
                        color: Color(red: 84/255, green: 0/255, blue: 232/255)
                    )
                }

                if let nearest = nearestLevelUp, nearest.level < 10 {
                    milestoneCard(
                        title: "Next Skill Level",
                        subtitle: nearest.name,
                        progress: nearest.progress,
                        detail: "\(nearest.nextThreshold - nearest.xp) XP to Level \(nearest.level + 1)",
                        icon: skillIcons[nearest.name] ?? "star.fill",
                        color: .green
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    private func milestoneCard(title: String, subtitle: String, progress: Double, detail: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(subtitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

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
            .frame(height: 8)

            Text(detail)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }

    // MARK: - Data Fetching

    private func fetchDailyLogs() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .collection("dailyLogs")
            .order(by: "date", descending: true)
            .limit(to: 7)
            .getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let logs = docs.compactMap { doc -> DailyLog? in
                    let data = doc.data()
                    guard let date = data["date"] as? String else { return nil }
                    return DailyLog(
                        date: date,
                        completedCount: data["completedCount"] as? Int ?? 0,
                        xpGained: data["xpGained"] as? Int ?? 0,
                        skillXP: data["skillXP"] as? [String: Int] ?? [:],
                        streak: data["streak"] as? Int ?? 0,
                        totalPossibleXP: data["totalPossibleXP"] as? Int ?? 0
                    )
                }
                DispatchQueue.main.async {
                    self.dailyLogs = logs.sorted { $0.date < $1.date }
                }
            }
    }

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        let db = Firestore.firestore()

        listener = db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }

            self.currentXP = data["xp"] as? Int ?? 0
            self.streak = data["streak"] as? Int ?? 0
            self.longestStreak = data["longestStreak"] as? Int ?? 0
            self.skillsData = data["skills"] as? [String: [String: Int]] ?? [:]

            let skillXP = data["todaySkillXP"] as? [String: Int] ?? [:]
            self.todayXP = skillXP.values.reduce(0, +)
            self.todayCompletedCount = (data["completedTasks"] as? [String])?.count ?? 0
            self.todayTotalPossibleXP = data["todayTotalPossibleXP"] as? Int ?? 0

            self.isLoading = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.animateBars = true
            }
        }
    }

    // MARK: - Helpers

    private func isInCurrentWeek(_ dateStr: String) -> Bool {
        guard let date = dateFromISO(dateStr) else { return false }
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: date) == calendar.component(.weekOfYear, from: Date())
            && calendar.component(.year, from: date) == calendar.component(.year, from: Date())
    }

    private func dayAbbreviation(from dateStr: String) -> String {
        guard let date = dateFromISO(dateStr) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "E"
        return fmt.string(from: date)
    }

    private func shortDate(from dateStr: String) -> String {
        guard let date = dateFromISO(dateStr) else { return "" }
        let calendar = Calendar.current
        return "\(calendar.component(.month, from: date))/\(calendar.component(.day, from: date))"
    }

    private func dateFromISO(_ str: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: str)
    }

    private func isoDateString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func formatXP(_ xp: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(xp))) ?? "\(Int(xp))"
    }
}

// MARK: - Header

private struct Header: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Your Insights")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("A glance at your balance and progress")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 8)
        .padding(.horizontal)
    }
}

