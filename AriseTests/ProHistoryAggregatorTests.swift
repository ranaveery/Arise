//
//  ProHistoryAggregatorTests.swift
//  AriseTests
//
//  Covers the prune-safe roll-up used by the Pro "All Time" range.
//

import Testing
import Foundation
@testable import Arise

struct ProHistoryAggregatorTests {

    private func log(_ date: String, xp: Int, completed: Int, possible: Int, streak: Int, skillXP: [String: Int] = [:]) -> DailyLog {
        DailyLog(date: date, completedCount: completed, xpGained: xp, skillXP: skillXP, streak: streak, totalPossibleXP: possible)
    }

    @Test func monthKeyUsesYearAndMonth() {
        #expect(ProHistoryAggregator.monthKey("2026-07-13") == "2026-07")
    }

    @Test func groupsLogsByMonth() {
        let logs = [
            log("2026-07-13", xp: 10, completed: 1, possible: 20, streak: 1),
            log("2026-07-20", xp: 30, completed: 2, possible: 40, streak: 2),
            log("2026-08-01", xp: 5, completed: 1, possible: 10, streak: 3)
        ]
        let summaries = ProHistoryAggregator.monthlySummaries(from: logs)

        #expect(summaries.count == 2)
        #expect(summaries["2026-07"]?.xpGained == 40)
        #expect(summaries["2026-07"]?.completedCount == 3)
        #expect(summaries["2026-07"]?.totalPossibleXP == 60)
        #expect(summaries["2026-07"]?.activeDays == 2)
        #expect(summaries["2026-08"]?.xpGained == 5)
    }

    @Test func bestStreakTakesMonthMaximum() {
        let logs = [
            log("2026-07-01", xp: 1, completed: 1, possible: 1, streak: 3),
            log("2026-07-02", xp: 1, completed: 1, possible: 1, streak: 9),
            log("2026-07-03", xp: 1, completed: 1, possible: 1, streak: 4)
        ]
        #expect(ProHistoryAggregator.monthlySummaries(from: logs)["2026-07"]?.bestStreak == 9)
    }

    @Test func inactiveDaysAreNotCounted() {
        let logs = [
            log("2026-07-01", xp: 0, completed: 0, possible: 0, streak: 0),
            log("2026-07-02", xp: 0, completed: 0, possible: 0, streak: 0)
        ]
        #expect(ProHistoryAggregator.monthlySummaries(from: logs)["2026-07"]?.activeDays == 0)
    }

    @Test func mergingAddsOntoExistingSummary() {
        let base = ["2026-07": MonthlySummary(xpGained: 10, completedCount: 1, totalPossibleXP: 20, bestStreak: 4, activeDays: 1)]
        let added = ["2026-07": MonthlySummary(xpGained: 5, completedCount: 2, totalPossibleXP: 10, bestStreak: 6, activeDays: 2)]

        let merged = ProHistoryAggregator.merging(added, into: base)
        #expect(merged["2026-07"]?.xpGained == 15)
        #expect(merged["2026-07"]?.completedCount == 3)
        #expect(merged["2026-07"]?.totalPossibleXP == 30)
        #expect(merged["2026-07"]?.bestStreak == 6)
        #expect(merged["2026-07"]?.activeDays == 3)
    }

    @Test func allTimeCombinesSummariesAndRetainedLogs() {
        let summaries = ["2026-06": MonthlySummary(xpGained: 100, completedCount: 5, totalPossibleXP: 200, bestStreak: 7, activeDays: 5)]
        let retained = [
            log("2026-07-01", xp: 20, completed: 2, possible: 40, streak: 8),
            log("2026-07-02", xp: 30, completed: 1, possible: 40, streak: 9)
        ]

        let stats = ProHistoryAggregator.allTimeStats(dailyLogs: retained, summaries: summaries)
        #expect(stats.totalXP == 150)
        #expect(stats.totalCompleted == 8)
        #expect(stats.totalPossibleXP == 280)
        #expect(stats.bestStreak == 9)
        #expect(stats.activeDays == 7)
        #expect(stats.months.map(\.id) == ["2026-06", "2026-07"])
        #expect(stats.earliestMonth == "2026-06")
    }

    @Test func summariesDecodeFromFirestoreMap() {
        let raw: [String: [String: Any]] = [
            "2026-07": ["xpGained": 12, "completedCount": 3, "totalPossibleXP": 30, "bestStreak": 5, "activeDays": 2]
        ]
        let decoded = ProHistoryAggregator.summaries(from: raw)
        #expect(decoded["2026-07"] == MonthlySummary(xpGained: 12, completedCount: 3, totalPossibleXP: 30, bestStreak: 5, activeDays: 2))
    }

    @Test func summariesDecodeIgnoresBadInput() {
        #expect(ProHistoryAggregator.summaries(from: nil).isEmpty)
        #expect(ProHistoryAggregator.summaries(from: "nope").isEmpty)
    }

    @Test func completionRateClampsToOne() {
        let summaries = ["2026-07": MonthlySummary(xpGained: 999, completedCount: 1, totalPossibleXP: 10, bestStreak: 1, activeDays: 1)]
        let stats = ProHistoryAggregator.allTimeStats(dailyLogs: [], summaries: summaries)
        #expect(stats.completionRate == 1.0)
    }
}