import SwiftUI
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Constants

let skillLevelThresholds: [Int] = [
    0,    // Level 1
    300,  // Level 2
    700,  // Level 3
    1000, // Level 4
    1700, // Level 5
    2300, // Level 6
    3000, // Level 7
    4000, // Level 8
    5000, // Level 9
    6700  // Level 10
]

func calculateSkillLevel(from xp: Int) -> Int {
    for (index, threshold) in skillLevelThresholds.enumerated().reversed() {
        if xp >= threshold { return index + 1 }
    }
    return 1
}

func skillProgress(for xp: Int) -> Double {
    let level = calculateSkillLevel(from: xp)
    let currentThreshold = skillLevelThresholds[level - 1]
    let nextThreshold = level < skillLevelThresholds.count
        ? skillLevelThresholds[level]
        : skillLevelThresholds.last ?? 0
    let range = nextThreshold - currentThreshold
    guard range > 0 else { return 1 }
    return min(max(Double(xp - currentThreshold) / Double(range), 0), 1.0)
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Brand Assets

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [
            Color(red: 84/255, green: 0/255, blue: 232/255),
            Color(red: 236/255, green: 71/255, blue: 1/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shared Constants

let allSkillNames = ["Discipline", "Fitness", "Fuel", "Network", "Resilience", "Wisdom"]

let skillIcons: [String: String] = [
    "Resilience": "brain",
    "Fuel":       "fork.knife",
    "Fitness":    "figure.run",
    "Wisdom":     "book.fill",
    "Discipline": "infinity",
    "Network":    "person.2.fill"
]

// MARK: - Models

struct SkillXP: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let level: Int
    let xp: Int

    var xpProgress: Double {
        min(Double(xp) / Double(currentLevelCap), 1.0)
    }

    var currentLevelCap: Int {
        skillLevelThresholds[min(level, skillLevelThresholds.count - 1)]
    }
}

struct Rank: Identifiable {
    let id: Int
    let name: String
    let emblemName: String
    let requiredXP: Double
    let subtitle: String
    let themeColors: [Color]
}

struct Achievement: Identifiable {
    let id = UUID()
    let index: Int
    var unlocked: Bool = false
    var title: String
    var imageName: String
    var description: String
    var quote: String
    var unlockedDate: String? = nil
}

let allAchievements: [Achievement] = [
    Achievement(index: 1,
                title: "The Journey Begins",
                imageName: "a1_image",
                description: "Reach Initiate.",
                quote: "Every master was once an initiate."),

    Achievement(index: 2,
                title: "Trailblazer",
                imageName: "a2_image",
                description: "Reach Pioneer.",
                quote: "Those who dare, lead the way."),

    Achievement(index: 3,
                title: "World Explorer",
                imageName: "a3_image",
                description: "Reach Explorer.",
                quote: "Adventure begins where comfort ends."),

    Achievement(index: 4,
                title: "Against All Odds",
                imageName: "a4_image",
                description: "Reach Challenger.",
                quote: "Greatness is forged in challenges."),

    Achievement(index: 5,
                title: "The Refiner's Flame",
                imageName: "a5_image",
                description: "Reach Refiner.",
                quote: "Through refinement, we find destiny — you're halfway there."),

    Achievement(index: 6,
                title: "Path to Mastery",
                imageName: "a6_image",
                description: "Reach Master.",
                quote: "Discipline transforms talent into mastery."),

    Achievement(index: 7,
                title: "The Conqueror",
                imageName: "a7_image",
                description: "Reach Conquerer.",
                quote: "Victory belongs to the relentless."),

    Achievement(index: 8,
                title: "Beyond Limits",
                imageName: "a8_image",
                description: "Reach Ascendant.",
                quote: "Rise above what you once thought impossible."),

    Achievement(index: 9,
                title: "Transcendent Being",
                imageName: "a9_image",
                description: "Reach Transcendent.",
                quote: "Transcendence is not the end, but a new beginning."),

    Achievement(index: 10,
                title: "First Steps",
                imageName: "a10_image",
                description: "You earned your very first XP!",
                quote: "Every journey begins with a single step."),

    Achievement(index: 11,
                title: "Flame of Discipline",
                imageName: "a11_image",
                description: "Reached level 10 in Discipline.",
                quote: "Consistency beats intensity."),

    Achievement(index: 12,
                title: "Peak Performer",
                imageName: "a12_image",
                description: "Reached Level 10 in Fitness.",
                quote: "Strength is built one rep at a time."),

    Achievement(index: 13,
                title: "Fuel of Champions",
                imageName: "a13_image",
                description: "Reached Level 10 in Fuel.",
                quote: "Discipline at the table shapes results in the gym."),

    Achievement(index: 14,
                title: "Master Connector",
                imageName: "a14_image",
                description: "Reached Level 10 in Network.",
                quote: "Your network is your net worth."),

    Achievement(index: 15,
                title: "Unbreakable Spirit",
                imageName: "a15_image",
                description: "Reached Level 10 in Resilience.",
                quote: "The strongest steel is forged in the hottest fire."),

    Achievement(index: 16,
                title: "Wisdom Seeker",
                imageName: "a16_image",
                description: "Reached Level 10 in Wisdom.",
                quote: "The beginning of wisdom is the search for it.")
]

struct DailyLog: Identifiable, Codable {
    var id: String { date }
    let date: String
    let completedCount: Int
    let xpGained: Int
    let skillXP: [String: Int]
    let streak: Int
    let totalPossibleXP: Int

    init(date: String, completedCount: Int, xpGained: Int, skillXP: [String: Int], streak: Int, totalPossibleXP: Int) {
        self.date = date
        self.completedCount = completedCount
        self.xpGained = xpGained
        self.skillXP = skillXP
        self.streak = streak
        self.totalPossibleXP = totalPossibleXP
    }

    /// Builds a log from a raw Firestore `dailyLogs.<date>` map.
    init?(date: String, dict: [String: Any]) {
        guard dict["xpGained"] != nil || dict["completedCount"] != nil || dict["totalPossibleXP"] != nil else {
            return nil
        }
        self.date = date
        self.completedCount = dict["completedCount"] as? Int ?? 0
        self.xpGained = dict["xpGained"] as? Int ?? 0
        self.skillXP = dict["skillXP"] as? [String: Int] ?? [:]
        self.streak = dict["streak"] as? Int ?? 0
        self.totalPossibleXP = dict["totalPossibleXP"] as? Int ?? 0
    }
}

// MARK: - Pro history roll-up

/// Compact per-month aggregate kept after the raw `dailyLogs` for that month
/// are pruned (120-day retention). Used to power the Pro "All Time" range.
struct MonthlySummary: Codable, Equatable {
    var xpGained: Int = 0
    var completedCount: Int = 0
    var totalPossibleXP: Int = 0
    var bestStreak: Int = 0
    var activeDays: Int = 0
    var skillXP: [String: Int] = [:]
}

/// One month of the all-time chart.
struct MonthlyStat: Identifiable, Equatable {
    let id: String
    let date: Date
    let xpGained: Int
    let completedCount: Int
    let totalPossibleXP: Int
    let bestStreak: Int
    let activeDays: Int
    var skillXP: [String: Int] = [:]
}

/// Aggregated, pruned-safe view of the user's entire history.
struct AllTimeStats: Equatable {
    var totalXP: Int = 0
    var totalCompleted: Int = 0
    var totalPossibleXP: Int = 0
    var bestStreak: Int = 0
    var activeDays: Int = 0
    var skillXP: [String: Int] = [:]
    var months: [MonthlyStat] = []
    var earliestMonth: String?

    var completionRate: Double {
        totalPossibleXP > 0 ? min(Double(totalXP) / Double(totalPossibleXP), 1) : 0
    }
}

/// Pure roll-up math shared by the prune path (DailyReset) and the Trends view.
enum ProHistoryAggregator {

    static func monthKey(_ dateStr: String) -> String {
        String(dateStr.prefix(7))
    }

    /// Groups raw daily logs into per-month summaries.
    static func monthlySummaries(from logs: [DailyLog]) -> [String: MonthlySummary] {
        var result: [String: MonthlySummary] = [:]
        for log in logs {
            let key = monthKey(log.date)
            var summary = result[key] ?? MonthlySummary()
            summary.xpGained += log.xpGained
            summary.completedCount += log.completedCount
            summary.totalPossibleXP += log.totalPossibleXP
            summary.bestStreak = max(summary.bestStreak, log.streak)
            if log.completedCount > 0 || log.xpGained > 0 {
                summary.activeDays += 1
            }
            for (skill, xp) in log.skillXP {
                summary.skillXP[skill, default: 0] += xp
            }
            result[key] = summary
        }
        return result
    }

    /// Adds `added` summaries on top of `base` (neither is mutated).
    static func merging(_ added: [String: MonthlySummary], into base: [String: MonthlySummary]) -> [String: MonthlySummary] {
        var result = base
        for (month, add) in added {
            var summary = result[month] ?? MonthlySummary()
            summary.xpGained += add.xpGained
            summary.completedCount += add.completedCount
            summary.totalPossibleXP += add.totalPossibleXP
            summary.bestStreak = max(summary.bestStreak, add.bestStreak)
            summary.activeDays += add.activeDays
            for (skill, xp) in add.skillXP {
                summary.skillXP[skill, default: 0] += xp
            }
            result[month] = summary
        }
        return result
    }

    /// Decodes the stored `monthlySummaries` Firestore map.
    static func summaries(from raw: Any?) -> [String: MonthlySummary] {
        guard let dict = raw as? [String: [String: Any]] else { return [:] }
        var result: [String: MonthlySummary] = [:]
        for (month, values) in dict {
            result[month] = MonthlySummary(
                xpGained: values["xpGained"] as? Int ?? 0,
                completedCount: values["completedCount"] as? Int ?? 0,
                totalPossibleXP: values["totalPossibleXP"] as? Int ?? 0,
                bestStreak: values["bestStreak"] as? Int ?? 0,
                activeDays: values["activeDays"] as? Int ?? 0,
                skillXP: values["skillXP"] as? [String: Int] ?? [:]
            )
        }
        return result
    }

    /// Combines pruned monthly summaries with the currently retained daily logs.
    /// The two sources are disjoint by construction (summaries cover dates older
    /// than the retention cutoff), so simple addition is correct.
    static func allTimeStats(dailyLogs: [DailyLog], summaries: [String: MonthlySummary]) -> AllTimeStats {
        let combined = merging(monthlySummaries(from: dailyLogs), into: summaries)
        var months: [MonthlyStat] = []
        for (month, summary) in combined {
            let date = AriseDate.date(fromISO: "\(month)-01") ?? Date.distantPast
            months.append(MonthlyStat(
                id: month,
                date: date,
                xpGained: summary.xpGained,
                completedCount: summary.completedCount,
                totalPossibleXP: summary.totalPossibleXP,
                bestStreak: summary.bestStreak,
                activeDays: summary.activeDays,
                skillXP: summary.skillXP
            ))
        }
        months.sort { $0.id < $1.id }
        return aggregate(months: months)
    }

    /// Totals for a set of months, optionally restricted to the trailing
    /// `monthsBack` months relative to `referenceDate` (used by the Pro "1Y" range).
    static func stats(
        dailyLogs: [DailyLog],
        summaries: [String: MonthlySummary],
        monthsBack: Int,
        referenceDate: Date = Date()
    ) -> AllTimeStats {
        let full = allTimeStats(dailyLogs: dailyLogs, summaries: summaries)
        let calendar = Calendar(identifier: .gregorian)
        let startOfReferenceMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: referenceDate)
        ) ?? referenceDate
        guard let cutoff = calendar.date(byAdding: .month, value: -(monthsBack - 1), to: startOfReferenceMonth) else {
            return full
        }
        let window = full.months.filter { $0.date >= cutoff }
        return aggregate(months: window)
    }

    /// Sums a list of monthly stats into an `AllTimeStats` value.
    static func aggregate(months: [MonthlyStat]) -> AllTimeStats {
        var stats = AllTimeStats()
        for month in months {
            stats.totalXP += month.xpGained
            stats.totalCompleted += month.completedCount
            stats.totalPossibleXP += month.totalPossibleXP
            stats.bestStreak = max(stats.bestStreak, month.bestStreak)
            stats.activeDays += month.activeDays
            for (skill, xp) in month.skillXP {
                stats.skillXP[skill, default: 0] += xp
            }
        }
        stats.months = months
        stats.earliestMonth = months.first?.id
        return stats
    }
}

/// Wrapper so `String` does not need a global `Identifiable` conformance.
struct IdentifiedString: Identifiable {
    let id: String
    init(_ value: String) { self.id = value }
    var value: String { id }
}

// MARK: - Arise Pro: Custom Tasks

/// A user-defined recurring task. Pro users may define several, but at most
/// `maxPerDay` are generated on any single day. XP is user-editable, capped at
/// `maxXP`.
struct CustomTask: Identifiable, Equatable {
    var id: String
    var name: String
    var details: String
    var xp: Int
    /// 1 = Monday ... 7 = Sunday (same convention as `DaysOfWeekPicker`).
    var days: [Int]
    var skillTargets: [String]

    static let maxPerDay = 2
    static let maxXP = 40
    static let maxDefinitions = 4

    init(
        id: String = UUID().uuidString,
        name: String,
        details: String = "",
        xp: Int = CustomTask.maxXP,
        days: [Int] = [],
        skillTargets: [String] = []
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.xp = min(max(xp, 5), CustomTask.maxXP)
        self.days = days
        self.skillTargets = skillTargets
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String, !name.isEmpty else { return nil }
        self.id = id
        self.name = name
        self.details = dict["details"] as? String ?? ""
        self.xp = min(max(dict["xp"] as? Int ?? CustomTask.maxXP, 5), CustomTask.maxXP)
        self.days = dict["days"] as? [Int] ?? []
        self.skillTargets = dict["skillTargets"] as? [String] ?? []
    }

    var firestoreValue: [String: Any] {
        [
            "id": id,
            "name": name,
            "details": details,
            "xp": xp,
            "days": days,
            "skillTargets": skillTargets
        ]
    }
}

enum CustomTaskScheduler {
    /// Tasks scheduled for a given weekday, capped at `CustomTask.maxPerDay`.
    /// Order is preserved (definition order), so the first matching tasks win.
    static func tasks(for dayIndex: Int, from tasks: [CustomTask]) -> [CustomTask] {
        var result: [CustomTask] = []
        for task in tasks where task.days.contains(dayIndex) {
            if result.count >= CustomTask.maxPerDay { break }
            result.append(task)
        }
        return result
    }
}

// MARK: - Arise Pro: Custom Reminders

/// A user-defined daily reminder (Pro). An empty `days` array means every day.
struct Reminder: Identifiable, Equatable {
    var id: String
    var label: String
    /// Local time formatted "HH:mm" (24-hour).
    var time: String
    /// 1 = Monday ... 7 = Sunday. Empty means every day.
    var days: [Int]
    var enabled: Bool

    static let maxReminders = 5

    init(id: String = UUID().uuidString, label: String, time: String, days: [Int] = [], enabled: Bool = true) {
        self.id = id
        self.label = label
        self.time = time
        self.days = days
        self.enabled = enabled
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let label = dict["label"] as? String,
              let time = dict["time"] as? String else { return nil }
        self.id = id
        self.label = label
        self.time = time
        self.days = dict["days"] as? [Int] ?? []
        self.enabled = dict["enabled"] as? Bool ?? true
    }

    var hour: Int {
        Int(time.split(separator: ":").first ?? "0") ?? 0
    }

    var minute: Int {
        guard time.contains(":") else { return 0 }
        return Int(time.split(separator: ":").last ?? "0") ?? 0
    }

    var daysLabel: String {
        guard !days.isEmpty, days.count < 7 else { return "Every day" }
        if Set(days) == [6, 7] { return "Weekends" }
        let names = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days.sorted().compactMap { names[safe: $0] }.joined(separator: ", ")
    }

    private var daysLabelFallback: String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days.sorted().compactMap { names[safe: $0 - 1] }.joined(separator: ", ")
    }

    /// Converts stored `[String: Any]` reminders into models.
    static func list(from raw: Any?) -> [Reminder] {
        guard let array = raw as? [[String: Any]] else { return [] }
        return array.compactMap { Reminder(dict: $0) }
    }

    func toDict() -> [String: Any] {
        ["id": id, "label": label, "time": time, "days": days, "enabled": enabled]
    }
}

// MARK: - Arise Pro: Insights

/// The extra, Pro-only signals shown in the Advanced Insights pack.
struct ProInsights: Equatable {
    var consistency: Double = 0
    var bestMonth: MonthlyStat?
    var momentumPct: Int?
    var skillTotals: [(skill: String, xp: Int)] = []

    static func == (lhs: ProInsights, rhs: ProInsights) -> Bool {
        lhs.consistency == rhs.consistency &&
        lhs.bestMonth?.id == rhs.bestMonth?.id &&
        lhs.momentumPct == rhs.momentumPct &&
        lhs.skillTotals.map(\.skill) == rhs.skillTotals.map(\.skill) &&
        lhs.skillTotals.map(\.xp) == rhs.skillTotals.map(\.xp)
    }
}

/// Pure computation of the Advanced Insights values.
enum ProInsightsEngine {
    /// Month-over-month XP change for the calendar month containing `referenceDate`.
    /// Returns `nil` when there isn't a prior month with XP to compare against.
    static func momentum(months: [MonthlyStat], referenceDate: Date = Date()) -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.year, .month], from: referenceDate)
        guard let year = comps.year, let month = comps.month else { return nil }
        let currentKey = String(format: "%04d-%02d", year, month)

        guard let previousDate = calendar.date(byAdding: .month, value: -1, to: referenceDate) else { return nil }
        let previousComps = calendar.dateComponents([.year, .month], from: previousDate)
        guard let previousYear = previousComps.year, let previousMonth = previousComps.month else { return nil }
        let previousKey = String(format: "%04d-%02d", previousYear, previousMonth)

        guard let current = months.first(where: { $0.id == currentKey }),
              let previous = months.first(where: { $0.id == previousKey }),
              previous.xpGained > 0 else { return nil }

        let change = (Double(current.xpGained) - Double(previous.xpGained)) / Double(previous.xpGained)
        return Int((change * 100).rounded())
    }

    static func bestMonth(months: [MonthlyStat]) -> MonthlyStat? {
        months.filter { $0.xpGained > 0 }.max { $0.xpGained < $1.xpGained }
    }

    static func skillTotals(from skillXP: [String: Int]) -> [(skill: String, xp: Int)] {
        skillXP
            .filter { $0.value > 0 }
            .map { (skill: $0.key, xp: $0.value) }
            .sorted { $0.xp > $1.xp }
    }

    static func consistency(activeDays: Int, windowDays: Int) -> Double {
        guard windowDays > 0 else { return 0 }
        return min(Double(activeDays) / Double(windowDays), 1)
    }
}

// MARK: - Arise Pro: Default notification time suggestions

/// Computes suggested "HH:mm" times for the three default notifications from the
/// user's weekday wake time and sleep duration. Kept pure so it can be unit
/// tested and reused by both the Settings UI and the scheduler.
///
/// Offsets intentionally mirror `SettingsView`'s scheduling exactly:
/// - New Tasks  = wake + 30 min
/// - Bedtime    = bedtime − 30 min (bedtime = wake − sleepHours)
/// - Expiring   = bedtime − 60 min
enum NotificationTimeSuggestion {
    enum Kind {
        case newTasks
        case bedtime
        case expiringTasks
    }

    /// - Parameters:
    ///   - wakeWeekday: weekday wake time as a military Int (e.g. `730` = 07:30).
    ///   - sleepHoursWeekday: weekday sleep duration in hours (e.g. `8` or `7.5`).
    /// - Returns: a zero-padded "HH:mm" string, or `nil` when data is missing/invalid.
    static func hhmm(for kind: Kind, wakeWeekday: Int?, sleepHoursWeekday: Double?) -> String? {
        guard let wakeWeekday else { return nil }
        let wakeHour = wakeWeekday / 100
        let wakeMinute = wakeWeekday % 100
        guard (0...23).contains(wakeHour), (0...59).contains(wakeMinute) else { return nil }

        var minutes = wakeHour * 60 + wakeMinute

        switch kind {
        case .newTasks:
            minutes += 30
        case .bedtime:
            guard let sleepHoursWeekday else { return nil }
            minutes += Int(-sleepHoursWeekday * 60) - 30
        case .expiringTasks:
            guard let sleepHoursWeekday else { return nil }
            minutes += Int(-sleepHoursWeekday * 60) - 60
        }

        minutes = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

/// The Pro user's custom times for the three default notifications.
/// A `nil` value means "use the suggested time" (derived from their schedule).
struct DefaultNotificationTimes: Equatable {
    var expiringTasks: String?
    var newTasks: String?
    var bedtime: String?

    static let empty = DefaultNotificationTimes()
}

// MARK: - Shared Services

extension Notification.Name {
    /// Posted after preferences are saved so the Settings screen can reschedule
    /// notifications without needing to be reopened.
    static let ariseRescheduleNotifications = Notification.Name("arise.rescheduleNotifications")
}

/// Single source of truth for the "yyyy-MM-dd" day string used for task IDs,
/// daily logs, and reset tracking. Always formats and parses in the device's
/// current time zone so round-tripping is consistent.
enum AriseDate {
    static func isoString(from date: Date) -> String {
        formatter().string(from: date)
    }
    static func date(fromISO str: String) -> Date? {
        formatter().date(from: str)
    }
    private static func formatter() -> DateFormatter {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone.current
        return fmt
    }
}

/// Single source of truth for achievement unlock rules, shared by the celebration
/// path (LoggingView) and the achievement gallery (RankDetailsView).
enum AchievementEngine {
    static func isUnlocked(_ achievement: Achievement, totalXP: Int, currentRankId: Int, skillXP: [String: Int]) -> Bool {
        switch achievement.index {
        case 1: return currentRankId >= 2
        case 2: return currentRankId >= 3
        case 3: return currentRankId >= 4
        case 4: return currentRankId >= 5
        case 5: return currentRankId >= 6
        case 6: return currentRankId >= 7
        case 7: return currentRankId >= 8
        case 8: return currentRankId >= 9
        case 9: return currentRankId >= 10
        case 10: return totalXP > 0
        case 11: return calculateSkillLevel(from: skillXP["Discipline"] ?? 0) >= 10
        case 12: return calculateSkillLevel(from: skillXP["Fitness"] ?? 0) >= 10
        case 13: return calculateSkillLevel(from: skillXP["Fuel"] ?? 0) >= 10
        case 14: return calculateSkillLevel(from: skillXP["Network"] ?? 0) >= 10
        case 15: return calculateSkillLevel(from: skillXP["Resilience"] ?? 0) >= 10
        case 16: return calculateSkillLevel(from: skillXP["Wisdom"] ?? 0) >= 10
        default: return false
        }
    }
}

/// App-wide daily rollover. Clears today-scoped fields on the user document and
/// prunes old `dailyLogs` entries when the calendar day changes. Runs from
/// MainTabView (always mounted), so it no longer depends on the Tasks tab.
enum DailyReset {
    static func performIfNeeded() {
        let today = AriseDate.isoString(from: Date())
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "lastResetDate") != today else { return }
        defaults.set(today, forKey: "lastResetDate")

        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.updateData([
            "completedTasks": [],
            "todaySkillXP": [:],
            "todayCompletedTaskDetails": []
        ]) { _ in
            userRef.getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                let rawLogs = data["dailyLogs"] as? [String: Any] ?? [:]
                let cutoff = AriseDate.isoString(from: Calendar.current.date(byAdding: .day, value: -120, to: Date()) ?? Date())

                var staleLogs: [DailyLog] = []
                var updates: [String: Any] = [:]
                for (key, value) in rawLogs where key < cutoff {
                    if let dict = value as? [String: Any], let log = DailyLog(date: key, dict: dict) {
                        staleLogs.append(log)
                    } else {
                        staleLogs.append(DailyLog(
                            date: key,
                            completedCount: 0,
                            xpGained: 0,
                            skillXP: [:],
                            streak: 0,
                            totalPossibleXP: 0
                        ))
                    }
                    updates["dailyLogs.\(key)"] = FieldValue.delete()
                }

                guard !staleLogs.isEmpty else { return }

                // Roll the pruned days into their monthly summaries so Pro's
                // "All Time" stats survive the 120-day retention window.
                let existing = ProHistoryAggregator.summaries(from: data["monthlySummaries"])
                let added = ProHistoryAggregator.monthlySummaries(from: staleLogs)
                let merged = ProHistoryAggregator.merging(added, into: existing)

                for month in added.keys {
                    let summary = merged[month] ?? MonthlySummary()
                    updates["monthlySummaries.\(month)"] = [
                        "xpGained": summary.xpGained,
                        "completedCount": summary.completedCount,
                        "totalPossibleXP": summary.totalPossibleXP,
                        "bestStreak": summary.bestStreak,
                        "activeDays": summary.activeDays,
                        "skillXP": summary.skillXP
                    ]
                }

                userRef.updateData(updates)
            }
        }
    }
}

// MARK: - Ranks

enum CelebrationEvent {
    case rankUp(Rank, Rank?)
    case achievement(Achievement)
}

let ranks: [Rank] = [
    Rank(id: 1,  name: "Seeker",       emblemName: "seeker_emblem",       requiredXP: 0,
         subtitle: "Every journey begins with a single step.",
         themeColors: [Color(red: 85/255,  green: 64/255,  blue: 44/255),
                       Color(red: 28/255,  green: 23/255,  blue: 19/255)]),
    Rank(id: 2,  name: "Initiate",     emblemName: "initiate_emblem",     requiredXP: 1800,
         subtitle: "Commitment is your first victory.",
         themeColors: [Color(red: 85/255,  green: 85/255,  blue: 85/255),
                       Color(red: 169/255, green: 169/255, blue: 169/255)]),
    Rank(id: 3,  name: "Pioneer",      emblemName: "pioneer_emblem",      requiredXP: 4200,
         subtitle: "Forge new paths, leave a mark.",
         themeColors: [Color(red: 184/255, green: 115/255, blue: 51/255),
                       Color(red: 93/255,  green: 46/255,  blue: 12/255)]),
    Rank(id: 4,  name: "Explorer",     emblemName: "explorer_emblem",     requiredXP: 6000,
         subtitle: "Seek the unknown, learn from everything.",
         themeColors: [Color(red: 153/255, green: 0/255,   blue: 0/255),
                       Color(red: 255/255, green: 85/255,  blue: 0/255)]),
    Rank(id: 5,  name: "Challenger",   emblemName: "challenger_emblem",   requiredXP: 10200,
         subtitle: "You only lose when you stop fighting.",
         themeColors: [Color(red: 155/255, green: 102/255, blue: 75/255),
                       Color(red: 33/255,  green: 64/255,  blue: 68/255)]),
    Rank(id: 6,  name: "Refiner",      emblemName: "refiner_emblem",      requiredXP: 13800,
         subtitle: "Strength is forged in relentless practice.",
         themeColors: [Color(red: 4/255,   green: 99/255,  blue: 7/255),
                       Color(red: 212/255, green: 175/255, blue: 55/255)]),
    Rank(id: 7,  name: "Master",       emblemName: "master_emblem",       requiredXP: 18000,
         subtitle: "Discipline shapes mastery.",
         themeColors: [Color(red: 11/255,  green: 29/255,  blue: 58/255),
                       Color(red: 64/255,  green: 224/255, blue: 208/255)]),
    Rank(id: 8,  name: "Conquerer",    emblemName: "conquerer_emblem",    requiredXP: 24000,
         subtitle: "Pain is the path to triumph.",
         themeColors: [Color(red: 71/255,  green: 12/255,  blue: 17/255),
                       Color(red: 86/255,  green: 105/255, blue: 162/255)]),
    Rank(id: 9,  name: "Ascendant",    emblemName: "ascendant_emblem",    requiredXP: 30000,
         subtitle: "Only by fighting do you rise.",
         themeColors: [Color(red: 10/255,  green: 55/255,  blue: 126/255),
                       Color(red: 180/255, green: 124/255, blue: 28/255)]),
    Rank(id: 10, name: "Transcendent", emblemName: "transcendent_emblem", requiredXP: 40200,
         subtitle: "All limits fall before you.",
         themeColors: [Color(red: 84/255,  green: 0/255,   blue: 232/255),
                       Color(red: 236/255, green: 71/255,  blue: 1/255)])
]

// MARK: - Shared Utilities

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                random = UInt8(arc4random_uniform(256))
            }
            return random
        }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

func sanitizeName(_ input: String) -> String {
    let allowedCharacterSet = CharacterSet.letters
        .union(.whitespaces)
        .union(CharacterSet(charactersIn: "'-"))
    let filtered = input.unicodeScalars
        .filter { allowedCharacterSet.contains($0) }
    let cleaned = String(String.UnicodeScalarView(filtered))
    let components = cleaned.split(separator: " ")
    let capitalized = components.map { word -> String in
        word.prefix(1).uppercased() + word.dropFirst().lowercased()
    }
    let result = capitalized.joined(separator: " ")
    return String(result.prefix(24))
}

func calculateBedtime(wakeTime: Date, sleepHours: Double) -> String? {
    let calendar = Calendar.current
    guard let bedtime = calendar.date(byAdding: .minute,
                                       value: Int(-sleepHours * 60),
                                       to: wakeTime) else { return nil }

    let minutes = calendar.component(.minute, from: bedtime)
    let remainder = minutes % 15
    let adjustment = remainder < 8 ? -remainder : (15 - remainder)
    guard let roundedBedtime = calendar.date(byAdding: .minute,
                                              value: adjustment,
                                              to: bedtime) else { return nil }

    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: roundedBedtime)
}

func militaryTimeInt(from date: Date) -> Int {
    let hour = Calendar.current.component(.hour, from: date)
    let minute = Calendar.current.component(.minute, from: date)
    return hour * 100 + minute
}
