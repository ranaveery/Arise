//
//  SharedStore.swift
//  Arise
//
//  Lightweight bridge between the app and the Arise home-screen widget via an
//  App Group. Intentionally free of WidgetKit so the same source can be shared
//  with both targets.
//

import Foundation

enum SharedStore {
    /// Must match the App Group enabled on both the app and widget targets.
    static let appGroupID = "group.com.ranaveer.Arise"

    private static let snapshotKey = "arise.widget.snapshot"

    /// A tiny, display-only summary of the user's day.
    struct Snapshot: Codable, Equatable {
        var streak: Int
        var completedToday: Int
        var totalToday: Int
        var isPro: Bool
        var updatedAt: Date

        static let placeholder = Snapshot(
            streak: 0,
            completedToday: 0,
            totalToday: 0,
            isPro: false,
            updatedAt: Date()
        )
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ snapshot: Snapshot) {
        guard let defaults,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func load() -> Snapshot? {
        guard let defaults,
              let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func clear() {
        defaults?.removeObject(forKey: snapshotKey)
    }
}