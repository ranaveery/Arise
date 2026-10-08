//
//  AriseWidget.swift
//  Arise
//
//  Home-screen widget. Pro users see today's progress and streak; free users
//  see a locked card that deep-links to the Arise Pro paywall (`arise://pro`).
//

import WidgetKit
import SwiftUI

private let widgetBrandGradient = LinearGradient(
    colors: [
        Color(red: 84/255, green: 0/255, blue: 232/255),
        Color(red: 236/255, green: 71/255, blue: 1/255)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct AriseEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedStore.Snapshot
}

struct AriseProvider: TimelineProvider {
    func placeholder(in context: Context) -> AriseEntry {
        AriseEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AriseEntry) -> Void) {
        completion(AriseEntry(date: Date(), snapshot: SharedStore.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AriseEntry>) -> Void) {
        let entry = AriseEntry(date: Date(), snapshot: SharedStore.load() ?? .placeholder)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct AriseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: AriseEntry

    var body: some View {
        Group {
            if entry.snapshot.isPro {
                proContent
            } else {
                lockedContent
            }
        }
        .containerBackground(for: .widget) {
            widgetBrandGradient
        }
    }

    private var proContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(entry.snapshot.streak)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("day streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer(minLength: 0)

            Text("Today")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.snapshot.completedToday)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("/ \(entry.snapshot.totalToday)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            ProgressView(value: progress)
                .tint(.white)
        }
        .padding(2)
    }

    private var lockedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Spacer(minLength: 0)
            Text("Unlock Arise Pro")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("See your streak & progress here")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(2)
        .widgetURL(URL(string: "arise://pro"))
    }

    private var progress: Double {
        guard entry.snapshot.totalToday > 0 else { return 0 }
        return min(1, Double(entry.snapshot.completedToday) / Double(entry.snapshot.totalToday))
    }
}

struct AriseWidget: Widget {
    let kind = "AriseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AriseProvider()) { entry in
            AriseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Arise")
        .description("Keep your streak and daily progress in view.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}