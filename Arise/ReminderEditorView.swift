//
//  ReminderEditorView.swift
//  Arise
//
//  Pro-only screen for customising the expiring-tasks reminder time and adding
//  up to `Reminder.maxReminders` extra personal reminders. Persistence is owned
//  by the caller via `onSave`, which also reschedules notifications.
//

import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: ([Reminder], String) -> Void

    @State private var reminders: [Reminder]
    @State private var expiringTime: String
    @State private var editingReminder: Reminder?
    @State private var isPresentingEditor = false

    init(reminders: [Reminder], expiringTasksTime: String, onSave: @escaping ([Reminder], String) -> Void) {
        _reminders = State(initialValue: reminders)
        _expiringTime = State(initialValue: expiringTasksTime)
        self.onSave = onSave
    }

    private var canAddMore: Bool { reminders.count < Reminder.maxReminders }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        expiringTimeCard
                        intro

                        if reminders.isEmpty {
                            emptyState
                        } else {
                            reminderList
                        }

                        addButton
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Custom Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(reminders.sorted { $0.time < $1.time }, expiringTime)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $isPresentingEditor) {
                ReminderItemEditorView(
                    reminder: editingReminder,
                    canAdd: canAddMore,
                    onSave: { upsert($0) }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var expiringTimeBinding: Binding<Date> {
        Binding(
            get: { Self.date(from: expiringTime) ?? Date() },
            set: { expiringTime = Self.hhmm(from: $0) }
        )
    }

    private var expiringTimeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Expiring Tasks Time")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text("When you're reminded to finish today's tasks")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            DatePicker("", selection: expiringTimeBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var intro: some View {
        Text("Add up to \(Reminder.maxReminders) extra reminders. Each can repeat on the days you choose.")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 34))
                .foregroundStyle(LinearGradient.brand)
            Text("No extra reminders")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Create a reminder for anything you want a nudge about.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var taskListCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                reminderRow(reminder)
                if index != reminders.count - 1 {
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
    }

    private var reminderList: some View { taskListCard }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 12) {
            Button {
                editingReminder = reminder
                isPresentingEditor = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(LinearGradient.brand)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(reminder.label)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(Self.prettyTime(reminder.time)) · \(reminder.daysLabel)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { reminder.enabled },
                set: { setEnabled(reminder, $0) }
            ))
            .labelsHidden()
            .tint(Color(red: 84/255, green: 0/255, blue: 232/255))

            Button(role: .destructive) {
                delete(reminder)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(reminder.label)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .accessibilityElement(children: .contain)
    }

    private var addButton: some View {
        Button {
            guard canAddMore else { return }
            editingReminder = nil
            isPresentingEditor = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text(canAddMore ? "Add Reminder" : "Maximum of \(Reminder.maxReminders) reached")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(canAddMore ? .white : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(canAddMore ? 0.06 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AnyShapeStyle(LinearGradient.brand), lineWidth: canAddMore ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canAddMore)
    }

    // MARK: - Mutations

    private func upsert(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
    }

    private func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
    }

    private func setEnabled(_ reminder: Reminder, _ enabled: Bool) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].enabled = enabled
    }

    // MARK: - Time helpers

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
    let canAdd: Bool
    let onSave: (Reminder) -> Void

    @State private var label: String
    @State private var time: Date
    @State private var days: Set<Int>
    @State private var enabled: Bool

    init(reminder: Reminder?, canAdd: Bool, onSave: @escaping (Reminder) -> Void) {
        self.reminder = reminder
        self.canAdd = canAdd
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
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            DaysOfWeekPicker(selection: $days)
                            Text(days.isEmpty ? "Every day" : "Selected days only")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Toggle(isOn: $enabled) {
                            Text("Enabled").foregroundColor(.white)
                        }
                        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(reminder == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
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

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func save() {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = Reminder(
            id: reminder?.id ?? UUID().uuidString,
            label: trimmed,
            time: ReminderEditorView.hhmm(from: time),
            days: days.sorted(),
            enabled: enabled
        )
        onSave(model)
        dismiss()
    }
}