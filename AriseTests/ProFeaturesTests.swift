//
//  ProFeaturesTests.swift
//  AriseTests
//
//  Covers the pure logic behind the Arise Pro feature pack: custom task
//  scheduling, reminder parsing, advanced insights, and the 1-year aggregate.
//

import Testing
import Foundation
@testable import Arise

struct CustomTaskSchedulerTests {

    private func task(_ id: String, days: [Int], xp: Int = 20) -> CustomTask {
        CustomTask(id: id, name: id, details: "", xp: xp, days: days, skillTargets: [])
    }

    @Test func returnsOnlyTasksMatchingTheDay() {
        let tasks = [task("a", days: [1]), task("b", days: [2]), task("c", days: [1, 2])]
        let monday = CustomTaskScheduler.tasks(for: 1, from: tasks)
        #expect(monday.map(\.id) == ["a", "c"])
    }

    @Test func capsAtMaxPerDayPreservingOrder() {
        let tasks = [
            task("a", days: [1]), task("b", days: [1]),
            task("c", days: [1]), task("d", days: [1])
        ]
        let result = CustomTaskScheduler.tasks(for: 1, from: tasks)
        #expect(result.count == CustomTask.maxPerDay)
        #expect(result.map(\.id) == ["a", "b"])
    }

    @Test func xpIsClampedToAllowedRange() {
        #expect(CustomTask(name: "x", details: "", xp: 100).xp == CustomTask.maxXP)
        #expect(CustomTask(name: "x", details: "", xp: 1).xp == 5)
        #expect(CustomTask(id: "x", name: "x", details: "", xp: 999, days: [1], skillTargets: []).xp == CustomTask.maxXP)
    }

    @Test func firestoreRoundTrip() {
        let original = CustomTask(id: "abc", name: "Read", details: "20 pages", xp: 30, days: [1, 3], skillTargets: ["Wisdom"])
        let restored = CustomTask(dict: original.firestoreValue)
        #expect(restored == original)
    }

    @Test func invalidDictReturnsNil() {
        #expect(CustomTask(dict: ["name": "no id"]) == nil)
    }
}

struct ReminderTests {

    @Test func parsesFromDict() {
        let dict: [String: Any] = ["id": "r1", "label": "Journal", "time": "21:30", "days": [1, 5], "enabled": true]
        let reminder = Reminder(dict: dict)
        #expect(reminder?.id == "r1")
        #expect(reminder?.hour == 21)
        #expect(reminder?.minute == 30)
        #expect(reminder?.days == [1, 5])
    }

    @Test func missingRequiredFieldsReturnsNil() {
        #expect(Reminder(dict: ["label": "no id", "time": "08:00"]) == nil)
        #expect(Reminder(dict: ["id": "r1", "time": "08:00"]) == nil)
    }

    @Test func roundTripThroughList() {
        let reminders = [
            Reminder(id: "a", label: "A", time: "07:00", days: [1], enabled: true),
            Reminder(id: "b", label: "B", time: "20:00", days: [], enabled: false)
        ]
        let restored = Reminder.list(from: reminders.map { $0.toDict() })
        #expect(restored == reminders)
    }

    @Test func emptyDaysMeansEveryDay() {
        #expect(Reminder(label: "A", time: "09:00").daysLabel == "Every day")
        #expect(Reminder(label: "A", time: "09:00", days: [6, 7]).daysLabel == "Weekends")
    }

    @Test func listIgnoresNonArrayInput() {
        #expect(Reminder.list(from: nil).isEmpty)
        #expect(Reminder.list(from: "nope").isEmpty)
    }
}

struct ProInsightsEngineTests {

    private func stat(_ id: String, xp: Int) -> MonthlyStat {
        MonthlyStat(id: id, date: AriseDate.date(fromISO: "\(id)-01") ?? Date(), xpGained: xp, completedCount: 0, totalPossibleXP: 0, bestStreak: 0, activeDays: 0, skillXP: [:])
    }

    @Test func momentumComputesPercentChange() {
        let months = [stat("2026-06", xp: 50), stat("2026-07", xp: 100)]
        let reference = AriseDate.date(fromISO: "2026-07-15") ?? Date()
        #expect(ProInsightsEngine.momentum(months: months, referenceDate: reference) == 100)
    }

    @Test func momentumNilWithoutPriorMonth() {
        let months = [stat("2026-07", xp: 100)]
        let reference = AriseDate.date(fromISO: "2026-07-15") ?? Date()
        #expect(ProInsightsEngine.momentum(months: months, referenceDate: reference) == nil)
    }

    @Test func bestMonthIgnoresEmptyMonths() {
        let months = [stat("2026-05", xp: 0), stat("2026-06", xp: 40), stat("2026-07", xp: 20)]
        #expect(ProInsightsEngine.bestMonth(months: months)?.id == "2026-06")
    }

    @Test func skillTotalsAreSortedDescending() {
        let totals = ProInsightsEngine.skillTotals(from: ["Fitness": 10, "Wisdom": 30, "Fuel": 0])
        #expect(totals.map(\.skill) == ["Wisdom", "Fitness"])
    }

    @Test func consistencyClampsAndHandlesZeroWindow() {
        #expect(ProInsightsEngine.consistency(activeDays: 5, windowDays: 10) == 0.5)
        #expect(ProInsightsEngine.consistency(activeDays: 20, windowDays: 10) == 1)
        #expect(ProInsightsEngine.consistency(activeDays: 5, windowDays: 0) == 0)
    }
}

struct YearAggregateTests {

    @Test func yearStatsRestrictsToTrailingTwelveMonths() {
        let summaries = [
            "2025-01": MonthlySummary(xpGained: 1000, completedCount: 0, totalPossibleXP: 0, bestStreak: 0, activeDays: 0),
            "2026-06": MonthlySummary(xpGained: 100, completedCount: 0, totalPossibleXP: 0, bestStreak: 0, activeDays: 0),
            "2026-07": MonthlySummary(xpGained: 50, completedCount: 0, totalPossibleXP: 0, bestStreak: 0, activeDays: 0)
        ]
        let reference = AriseDate.date(fromISO: "2026-07-15") ?? Date()
        let stats = ProHistoryAggregator.stats(dailyLogs: [], summaries: summaries, monthsBack: 12, referenceDate: reference)
        #expect(stats.totalXP == 150)
        #expect(!stats.months.contains { $0.id == "2025-01" })
    }

    @Test func aggregateSumsSkillXP() {
        let logs = [
            DailyLog(date: "2026-07-01", completedCount: 1, xpGained: 30, skillXP: ["Wisdom": 20, "Fitness": 10], streak: 1, totalPossibleXP: 30),
            DailyLog(date: "2026-07-02", completedCount: 1, xpGained: 10, skillXP: ["Wisdom": 10], streak: 2, totalPossibleXP: 10)
        ]
        let stats = ProHistoryAggregator.allTimeStats(dailyLogs: logs, summaries: [:])
        #expect(stats.skillXP["Wisdom"] == 30)
        #expect(stats.skillXP["Fitness"] == 10)
    }
}