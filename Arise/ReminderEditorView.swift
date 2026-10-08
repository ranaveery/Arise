//
//  ReminderEditorView.swift
//  Arise
//
//  Pro-only screen for the default reminders (Expiring Tasks / New Tasks / Bedtime)
//  with Apple time pickers, and up to `Reminder.maxReminders` extra personal reminders.
//  Persistence is owned by the caller via `onSave`.

import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: ([Reminder], DefaultNotificationTimes) -> Void

    @State private var reminders: [Reminder]
    @State private var times: DefaultNotificationTimes
    let suggestions: DefaultNotificationTimes
    @State private var expandedDefault: String?
    @State private var editorContext: EditorContext?

    private struct EditorContext: Identifiable {
        let id = UUID()
        let reminder: Reminder?
    }

    init(reminders: [Reminder],
         times: DefaultNotificationTimes,
         suggestions: DefaultNotificationTimes,
         onSave: @escaping ([Reminder], DefaultNotificationTimes) -> Void) {
        _reminders = State(initialValue: reminders)
        _times = State(initialValue: times)
        self.suggestions = suggestions
        self.onSave = onSave
    }

    private var canAddMore: Bool { reminders.count < Reminder.maxReminders }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        defaultRemindersSection
                        VStack(alignment: .leading, spacing: 16) {
                            sectionLabel("CUSTOM REMINDERS")
                            intro
                            if reminders.isEmpty {
                                emptyState
                            } else {
                                reminderList
                            }
                            addButton
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(reminders.sorted { $0.time < $1.time }, times)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
            }
            .sheet(item: $editorContext) { context in
                ReminderItemEditorView(reminder: context.reminder) { upsert($0) }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.4))
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var defaultRemindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("DEFAULT REMINDERS")
            VStack(spacing: 0) {
                defaultRow(icon: "clock.badge.exclamationmark", title: "Expiring Tasks", keyPath: \.expiringTasks, suggestion: suggestions.expiringTasks)
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                defaultRow(icon: "plus.square.on.square", title: "New Tasks", keyPath: \.newTasks, suggestion: suggestions.newTasks)
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                defaultRow(icon: "moon.fill", title: "Bedtime", keyPath: \.bedtime, suggestion: suggestions.bedtime)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func defaultRow(icon: String, title: String, keyPath: WritableKeyPath<DefaultNotificationTimes, String?>, suggestion: String?) -> some View {
        let isExpanded = expandedDefault == title
        let custom = times[keyPath: keyPath]
        let displayed = custom ?? suggestion
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) { expandedDefault = isExpanded ? nil : title }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon).font(.system(size: 15)).foregroundStyle(LinearGradient.brand).frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Text(custom != nil ? "Custom time" : (suggestion != nil ? "Suggested from your schedule" : "No schedule set"))
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                    if let displayed { Text(Self.prettyTime(displayed)).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.9)) }
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.35)).rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16).padding(.vertical, 13).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isExpanded {
                defaultTimeEditor(keyPath: keyPath, suggestion: suggestion, custom: custom)
            }
        }
    }

    private func defaultTimeEditor(keyPath: WritableKeyPath<DefaultNotificationTimes, String?>, suggestion: String?, custom: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DatePicker("", selection: Binding(
                get: { Self.date(from: times[keyPath: keyPath] ?? suggestion ?? "18:00") ?? Date() },
                set: { times[keyPath: keyPath] = Self.hhmm(from: $0) }
            ), displayedComponents: .hourAndMinute)
                .labelsHidden().tint(.white).frame(maxWidth: .infinity, alignment: .trailing).padding(.trailing, 6)
            HStack {
                Text(custom != nil ? "Custom time — tap Save to apply" : "Using suggested time from your schedule")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.4)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if custom != nil {
                    Button("Reset to suggested") { times[keyPath: keyPath] = nil }
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.65))
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14).background(Color.white.opacity(0.03))
    }

    private var intro: some View {
        Text("Add up to \(Reminder.maxReminders) extra reminders. Each can repeat on the days you choose.")
            .font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(LinearGradient.brand.opacity(0.15)).frame(width: 64, height: 64)
                Image(systemName: "bell.badge").font(.system(size: 28)).foregroundStyle(LinearGradient.brand)
            }
            Text("No extra reminders").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
            Text("Create a custom nudge for anything you’d like to stay on top of.")
                .font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center).padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40).padding(.horizontal, 20)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var reminderList: some View {
        VStack(spacing: 0) {
            ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                reminderRow(reminder)
                if index != reminders.count - 1 {
                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                }
            }
        }
        .background(Color.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 12) {
            Button { editorContext = EditorContext(reminder: reminder) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill").font(.system(size: 15)).foregroundStyle(LinearGradient.brand).frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reminder.label).font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                        Text("\(Self.prettyTime(reminder.time)) · \(reminder.daysLabel)").font(.system(size: 12)).foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Toggle("", isOn: Binding(get: { reminder.enabled }, set: { setEnabled(reminder, $0) })).labelsHidden().tint(Color(red: 84/255, green: 0/255, blue: 232/255))
            Button(role: .destructive) { delete(reminder) } label: {
                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(.red.opacity(0.85))
            }.buttonStyle(.plain).accessibilityLabel("Delete \(reminder.label)")
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var addButton: some View {
        Button {
            guard canAddMore else { return }
            editorContext = EditorContext(reminder: nil)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(LinearGradient.brand)
                Text(canAddMore ? "Add Custom Reminder" : "Maximum of \(Reminder.maxReminders) reached")
                    .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(canAddMore ? .white : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(canAddMore ? 0.06 : 0.03)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(canAddMore ? AnyShapeStyle(LinearGradient.brand.opacity(0.5)) : AnyShapeStyle(Color.clear), lineWidth: 1.5))
        }
        .buttonStyle(.plain).disabled(!canAddMore)
    }

    private func upsert(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) { reminders[index] = reminder } else { reminders.append(reminder) }
    }
    private func delete(_ reminder: Reminder) { reminders.removeAll { $0.id == reminder.id } }
    private func setEnabled(_ reminder: Reminder, _ enabled: Bool) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].enabled = enabled
    }
}

extension ReminderEditorView {
    static func date(from hhmm: String) -> Date? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return Calendar.current.date(from: DateComponents(hour: h, minute: m))
    }
    static func hhmm(from date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }
    static func prettyTime(_ hhmm: String) -> String {
        guard let date = date(from: hhmm) else { return hhmm }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - Editor sheet
private struct ReminderItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let reminder: Reminder?
    let onSave: (Reminder) -> Void
    @State private var label: String
    @State private var time: Date
    @State private var days: Set<Int>
    @State private var enabled: Bool

    init(reminder: Reminder?, onSave: @escaping (Reminder) -> Void) {
        self.reminder = reminder
        self.onSave = onSave
        _label = State(initialValue: reminder?.label ?? "")
        _time = State(initialValue: ReminderEditorView.date(from: reminder?.time ?? "18:00") ?? Date())
        _days = State(initialValue: Set(reminder?.days ?? []))
        _enabled = State(initialValue: reminder?.enabled ?? true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        field("Reminder") {
                            TextField("e.g. Journal before bed", text: $label)
                                .textInputAutocapitalization(.sentences)
                                .foregroundColor(.white)
                        }
                        field("Time") {
                            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat").font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            DaysOfWeekPicker(selection: $days)
                            Text(days.isEmpty ? "Every day" : "Selected days only").font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                        }
                        Toggle(isOn: $enabled) { Text("Enabled").foregroundColor(.white) }
                            .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(reminder == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var canSave: Bool { !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.7))
            content()
                .padding(.horizontal, 14).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    private func save() {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = Reminder(id: reminder?.id ?? UUID().uuidString, label: trimmed, time: ReminderEditorView.hhmm(from: time), days: days.sorted(), enabled: enabled)
        onSave(model)
        dismiss()
    }
}
