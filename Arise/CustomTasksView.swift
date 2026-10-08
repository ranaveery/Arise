//
//  CustomTasksView.swift
//  Arise
//
//  Pro-only management screen for user-defined recurring tasks. Up to
//  `CustomTask.maxDefinitions` may be defined; at most `CustomTask.maxPerDay`
//  are added to the daily list on any given day.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CustomTasksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var tasks: [CustomTask] = []
    @State private var isLoading = true
    @State private var editingTask: CustomTask?
    @State private var isPresentingEditor = false
    @State private var errorMessage: String?

    private var canAddMore: Bool { tasks.count < CustomTask.maxDefinitions }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            intro

                            if tasks.isEmpty {
                                emptyState
                            } else {
                                taskList
                            }

                            addButton

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Custom Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $isPresentingEditor) {
                CustomTaskEditorView(
                    task: editingTask,
                    canAdd: canAddMore,
                    onSave: { saved in upsert(saved) }
                )
            }
        }
        .preferredColorScheme(.dark)
        .task { loadTasks() }
    }

    private var intro: some View {
        Text("Up to \(CustomTask.maxPerDay) custom tasks are added each day. Choose the days they appear and the skills they build.")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 34))
                .foregroundStyle(LinearGradient.brand)
            Text("No custom tasks yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Add a personal habit and it'll appear in your daily list on the days you choose.")
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

    private var taskList: some View {
        VStack(spacing: 0) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                taskRow(task)

                if index != tasks.count - 1 {
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

    private func taskRow(_ task: CustomTask) -> some View {
        Button {
            editingTask = task
            isPresentingEditor = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 16))
                    .foregroundStyle(LinearGradient.brand)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle(for: task))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("+\(task.xp) XP")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LinearGradient.brand)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(LinearGradient.brand.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.name), \(subtitle(for: task)), plus \(task.xp) XP")
    }

    private func subtitle(for task: CustomTask) -> String {
        let days = dayLabel(task.days)
        let skills = task.skillTargets.isEmpty ? "All skills" : task.skillTargets.joined(separator: ", ")
        return "\(days) · \(skills)"
    }

    private func dayLabel(_ days: [Int]) -> String {
        guard !days.isEmpty, days.count < 7 else { return "Every day" }
        let names = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days.sorted().compactMap { names[safe: $0] }.joined(separator: ", ")
    }

    private var addButton: some View {
        Button {
            guard canAddMore else { return }
            editingTask = nil
            isPresentingEditor = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text(canAddMore ? "Add Custom Task" : "Maximum of \(CustomTask.maxDefinitions) reached")
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
        .accessibilityHint(canAddMore ? "Adds a new custom task" : "Maximum number of custom tasks reached")
    }

    // MARK: - Persistence

    private func loadTasks() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            let raw = snapshot?.data()?["customTasks"] as? [[String: Any]] ?? []
            let loaded = raw.compactMap { CustomTask(dict: $0) }
            DispatchQueue.main.async {
                self.tasks = loaded
                self.isLoading = false
                if error != nil { self.errorMessage = "Couldn't load your custom tasks." }
            }
        }
    }

    private func upsert(_ task: CustomTask) {
        if task.days.isEmpty {
            // An empty day set is our deletion tombstone.
            tasks.removeAll { $0.id == task.id }
        } else if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        persist()
    }

    private func persist() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = tasks.map { $0.firestoreValue }
        Firestore.firestore().collection("users").document(uid).setData(
            ["customTasks": values],
            merge: true
        ) { error in
            if let error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - Editor

private struct CustomTaskEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let task: CustomTask?
    let canAdd: Bool
    let onSave: (CustomTask) -> Void

    @State private var name: String
    @State private var details: String
    @State private var xp: Int
    @State private var days: Set<Int>
    @State private var skills: Set<String>

    init(task: CustomTask?, canAdd: Bool, onSave: @escaping (CustomTask) -> Void) {
        self.task = task
        self.canAdd = canAdd
        self.onSave = onSave
        _name = State(initialValue: task?.name ?? "")
        _details = State(initialValue: task?.details ?? "")
        _xp = State(initialValue: task?.xp ?? CustomTask.maxXP)
        _days = State(initialValue: Set(task?.days ?? []))
        _skills = State(initialValue: Set(task?.skillTargets ?? []))
    }

    private var isEditing: Bool { task != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !days.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        fieldCard

                        VStack(alignment: .leading, spacing: 10) {
                            ProSectionTitle(title: "Days")
                            DaysOfWeekPicker(selection: $days)
                            Text("Pick at least one day.")
                                .font(.system(size: 12))
                                .foregroundColor(days.isEmpty ? .red.opacity(0.8) : .white.opacity(0.35))
                        }
                        .padding(.horizontal)

                        skillsSection

                        if isEditing {
                            deleteButton
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(canSave ? .white : .white.opacity(0.3))
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var fieldCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Name").foregroundColor(.white.opacity(0.7)).frame(width: 74, alignment: .leading)
                TextField("e.g. Journal", text: $name)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)

            HStack(spacing: 12) {
                Text("Details").foregroundColor(.white.opacity(0.7)).frame(width: 74, alignment: .leading)
                TextField("Optional description", text: $details)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)

            HStack(spacing: 12) {
                Text("XP").foregroundColor(.white.opacity(0.7)).frame(width: 74, alignment: .leading)
                Stepper(value: $xp, in: 5...CustomTask.maxXP, step: 5) {
                    Text("\(xp) XP")
                        .foregroundColor(.white)
                }
                .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProSectionTitle(title: "Skills")
            Text("Leave empty to spread XP across all skills.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 4)

            FlowingChips(items: allSkillNames, selection: $skills)
        }
        .padding(.horizontal)
    }

    private var deleteButton: some View {
        Button {
            guard let task else { return }
            onDelete(task)
            dismiss()
        } label: {
            Text("Delete Task")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    /// Deleting is modelled by saving a task with the same id but no days, which
    /// the parent removes. To keep the closure simple, we reuse `onSave` with a
    /// sentinel by asking the parent to drop ids with empty days.
    private func onDelete(_ task: CustomTask) {
        var tombstone = task
        tombstone.days = []
        onSave(tombstone)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = CustomTask(
            id: task?.id ?? UUID().uuidString,
            name: trimmedName,
            details: trimmedDetails,
            xp: xp,
            days: days.sorted(),
            skillTargets: allSkillNames.filter { skills.contains($0) }
        )
        onSave(model)
        dismiss()
    }
}

// MARK: - Chips

private struct FlowingChips: View {
    let items: [String]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection.contains(item)
                Button {
                    if isSelected { selection.remove(item) } else { selection.insert(item) }
                } label: {
                    Text(item)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(isSelected ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.white.opacity(0.06)))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
                rows.append([])
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}