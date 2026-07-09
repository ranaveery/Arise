import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Model
struct TaskItem: Identifiable, Equatable {
    // id is deterministic per-day string so the same task has the same id across reloads
    let id: String
    let name: String
    let description: String
    let xp: Int
    let expiresInHours: Int
    let internalType: String
    let skillTargets: [String]?
    
    // equality based on id
    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - LoggingView
struct LoggingView: View {
    // user
    @State private var userName: String = "User"
    @State private var streak: Int = 0
    @Namespace private var tabAnimation
    @Environment(\.scenePhase) private var scenePhase

    // tasks
    @State private var assignedTasks: [TaskItem] = []
    @State private var completedTaskIDs: [String] = [] // persisted in Firestore
    @State private var expandedTaskID: String? = nil
    
    // completed list derived from completedTaskIDs & assigned tasks
    private var completedTasks: [TaskItem] {
        // show most recently completed first (we'll keep insertion order by ID presence; Firestore doesn't provide timestamps here)
        assignedTasks.filter { completedTaskIDs.contains($0.id) }
    }
    
    // assigned visible tasks (excluding completed)
    private var visibleAssignedTasks: [TaskItem] {
        assignedTasks.filter { !completedTaskIDs.contains($0.id) }
    }
    
    // UI
    @State private var isLoading = true
    @State private var userData: [String: Any] = [:]
    @State private var selectedTab: TabOption = .assigned
    @AppStorage("lastResetDate") private var lastResetDate = ""
    @State private var todayTotalPossibleXP: Int = 0
    @AppStorage("lastRankId") private var lastRankId: Int = 0
    @Binding var showCelebration: Bool
    @Binding var celebrationRank: Rank?
    @Binding var celebrationPrevRank: Rank?
    
    // Timer to check for midnight (fires every minute)
    private let midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    enum TabOption: String, CaseIterable {
        case assigned = "Assigned"
        case completed = "Completed"
    }
    
    private var accentGradient: LinearGradient { LinearGradient.brand }

    private var todayXP: Int {
        guard let xpDict = userData["todaySkillXP"] as? [String: Int] else { return 0 }
        return xpDict.values.reduce(0, +)
    }

    private var completionPercentage: Double {
        guard !assignedTasks.isEmpty else { return 0 }
        return Double(completedTaskIDs.count) / Double(assignedTasks.count)
    }

    private var sectionedTasks: [(String, [TaskItem])] {
        let grouped = Dictionary(grouping: visibleAssignedTasks) { $0.internalType }
        let sectionMap: [String: String] = [
            "Daily": "Daily Rituals",
            "Set Day": "Set Day",
            "Addiction": "Addiction Focus"
        ]
        return ["Addiction", "Daily", "Set Day"].compactMap { key in
            guard let tasks = grouped[key], !tasks.isEmpty else { return nil }
            return (sectionMap[key] ?? key, tasks)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            headerView

                            tabsView

                            todayStatsView

                            if selectedTab == .assigned {
                                assignedTaskList
                            } else {
                                completedTaskList
                            }
                        }
                        .padding(.top, 8)
                    }
                    .scrollIndicators(.hidden)
                    .onReceive(midnightTimer) { _ in
                        checkForMidnightReset()
                    }
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        if newPhase == .active {
                            checkForMidnightReset()
                            fetchUserData()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                checkForMidnightReset()
                fetchUserData()
            }
        }
    }

    // MARK: - Today Stats
    private var todayStatsView: some View {
        HStack(spacing: 0) {
            statItem(value: "\(completedTaskIDs.count)/\(assignedTasks.count)", label: "Done", icon: "checkmark.circle.fill", color: .green)
            Divider().frame(height: 28).background(Color.white.opacity(0.1))
            statItem(value: "\(todayXP)", label: "XP", icon: "bolt.fill", color: Color(red: 84/255, green: 0/255, blue: 232/255))
            Divider().frame(height: 28).background(Color.white.opacity(0.1))
            statItem(value: "\(streak)", label: "Streak", icon: "flame.fill", color: .orange)
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("Tasks")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedToday)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    private var formattedToday: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: Date())
    }

    // MARK: - Tabs
    private var tabsView: some View {
        HStack(spacing: 0) {
            ForEach(TabOption.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                        expandedTaskID = nil
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(accentGradient)
                                        .matchedGeometryEffect(id: "tab", in: tabAnimation)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Task lists
    private var assignedTaskList: some View {
        VStack(spacing: 14) {
            if visibleAssignedTasks.isEmpty {
                emptyStateView
            } else {
                ForEach(sectionedTasks, id: \.0) { section, tasks in
                    sectionHeader(title: section, count: tasks.count)
                    ForEach(tasks) { task in
                        TaskCard(
                            task: task,
                            isCompleted: false,
                            isExpanded: expandedTaskID == task.id,
                            accentGradient: accentGradient,
                            onTap: { toggleExpand(task) },
                            onComplete: { markComplete(task) },
                            onPartial: { markPartial(task) },
                            onUndo: nil,
                            timeRemaining: timeRemainingString()
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 60)
    }

    private var completedTaskList: some View {
        VStack(spacing: 14) {
            let completed = completedTasks
            if completed.isEmpty {
                emptyStateView
            } else {
                ForEach(completed) { task in
                    TaskCard(
                        task: task,
                        isCompleted: true,
                        isExpanded: false,
                        accentGradient: accentGradient,
                        onTap: nil,
                        onComplete: nil,
                        onPartial: nil,
                        onUndo: { undoCompleteTask(task) },
                        timeRemaining: timeRemainingString()
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 60)
    }

    // MARK: - Empty state
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(selectedTab == .assigned ? "All tasks complete!" : "No tasks completed yet")
                .foregroundColor(.white)
                .font(.title3.weight(.semibold))
            Text(selectedTab == .assigned ? "Great work today." : "Complete some tasks to see them here.")
                .foregroundColor(.white.opacity(0.65))
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Section header
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: sectionIcon(for: title))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accentGradient)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text("\(count) left")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }

    private func sectionIcon(for title: String) -> String {
        switch title {
        case "Daily Rituals": return "sun.max.fill"
        case "Set Day": return "calendar.day.timeline.left"
        case "Addiction Focus": return "flame.fill"
        default: return "circle.fill"
        }
    }

    // MARK: - Toggle Expand
    private func toggleExpand(_ task: TaskItem) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            if expandedTaskID == task.id {
                expandedTaskID = nil
            } else {
                expandedTaskID = task.id
            }
        }
    }
}

// MARK: - Firestore + Task logic
extension LoggingView {
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if error != nil {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            guard let data = snapshot?.data() else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            
            DispatchQueue.main.async {
                self.userData = data
                self.userName = (data["name"] as? String) ?? "User"
                self.streak = (data["streak"] as? Int) ?? 0
                self.completedTaskIDs = (data["completedTasks"] as? [String]) ?? []
                
                // check continuity (resets streak if broken)
                handleStreakContinuity(using: data)
                
                // generate tasks for today (IDs deterministic per day)
                self.generateTasks(from: data)
                if self.todayTotalPossibleXP > 0 {
                    userRef.updateData(["todayTotalPossibleXP": self.todayTotalPossibleXP])
                }
                self.isLoading = false
            }
        }
    }
    
    private func makeTasks(from data: [String: Any], date: Date) -> [TaskItem] {
        var newTasks: [TaskItem] = []
        let calendar = Calendar.current
        let daySystem = calendar.component(.weekday, from: date)
        let dayIndex = (daySystem == 1) ? 7 : (daySystem - 1)
        let isWeekend = (dayIndex == 6 || dayIndex == 7)
        let dateStr = dateStringForIDs(from: date)

        // --- Daily: wake / sleep ---
        if let wakeInt = data[isWeekend ? "wakeWeekend" : "wakeWeekday"] as? Int,
           let sleepHours = data[isWeekend ? "sleepHoursWeekend" : "sleepHoursWeekday"] as? Double {
            if let wakeDate = timeFromMilitaryInt(wakeInt),
               let bedtime = calculateBedtime(wakeTime: wakeDate, sleepHours: sleepHours) {
                let wakeReadable = formattedTime(from: wakeDate)
                newTasks.append(TaskItem(
                    id: idForTask(name: "Arise and Shine", description: "Wake up at \(wakeReadable)", day: dateStr),
                    name: "Arise and Shine",
                    description: "Wake up at \(wakeReadable)",
                    xp: 40,
                    expiresInHours: 6,
                    internalType: "Daily",
                    skillTargets: ["Discipline", "Resilience"]
                ))

                newTasks.append(TaskItem(
                    id: idForTask(name: "Bedtime", description: "Sleep by \(bedtime) to hit your sleep goal", day: dateStr),
                    name: "Bedtime",
                    description: "Sleep by \(bedtime) to hit your sleep goal",
                    xp: 40,
                    expiresInHours: 12,
                    internalType: "Daily",
                    skillTargets: ["Fuel", "Wisdom"]
                ))
            }
        }

        // --- Daily: water & screen ---
        if data["waterOunces"] as? Int != nil {
            newTasks.append(TaskItem(
                id: idForTask(name: "Water Intake", description: "Drink \(data["waterOunces"] as? Int ?? 0) oz of water", day: dateStr),
                name: "Water Intake",
                description: "Drink \(data["waterOunces"] as? Int ?? 0) oz of water",
                xp: 40,
                expiresInHours: 10,
                internalType: "Daily",
                skillTargets: ["Fuel", "Fitness"]
            ))
        }

        if data["screenLimitHours"] as? Int != nil {
            newTasks.append(TaskItem(
                id: idForTask(name: "Screen Time Limit", description: "Stay under \(data["screenLimitHours"] as? Int ?? 0) hours of screen time", day: dateStr),
                name: "Screen Time Limit",
                description: "Stay under \(data["screenLimitHours"] as? Int ?? 0) hours of screen time",
                xp: 40,
                expiresInHours: 10,
                internalType: "Daily",
                skillTargets: ["Discipline", "Wisdom"]
            ))
        }

        // --- Set-day: workouts ---
        let workoutDays = intArray(from: data["workoutDays"])
        if workoutDays.contains(dayIndex),
           let workoutHoursAny = data["workoutHoursPerDay"] {
            let workoutHours: Int
            if let intVal = workoutHoursAny as? Int { workoutHours = intVal }
            else if let n = workoutHoursAny as? NSNumber { workoutHours = n.intValue }
            else if let s = workoutHoursAny as? String, let i = Int(s) { workoutHours = i }
            else { workoutHours = 0 }

            if workoutHours > 0 {
                let minutes = workoutHours * 60
                newTasks.append(TaskItem(
                    id: idForTask(name: "Workout", description: "Workout for \(minutes) minutes", day: dateStr),
                    name: "Workout",
                    description: "Workout for \(minutes) minutes",
                    xp: 40,
                    expiresInHours: 12,
                    internalType: "Set Day",
                    skillTargets: ["Fitness", "Resilience"]
                ))
            }
        }

        // --- Set-day: Cold Showers ---
        let coldDays = intArray(from: data["coldShowerDays"])
        if coldDays.contains(dayIndex) {
            newTasks.append(TaskItem(
                id: idForTask(name: "Cold Shower", description: "Take a cold shower", day: dateStr),
                name: "Cold Shower",
                description: "Take a cold shower",
                xp: 40,
                expiresInHours: 12,
                internalType: "Set Day",
                skillTargets: ["Resilience", "Discipline"]
            ))
        }

        // --- Set-day: custom selectedActivities ---
        if let selectedActivities = data["selectedActivities"] as? [String: [Int]] {
            let activitySkillMap: [String: [String]] = [
                "meditation": ["Wisdom"],
                "reading": ["Wisdom"],
                "pray": ["Wisdom"],
                "study": ["Wisdom"],
                "walk": ["Fitness", "Fuel"],
                "run": ["Fitness"]
            ]

            let activityDescriptions: [String: String] = [
                "meditation": "Spend time meditating to center your mind",
                "reading": "Read to expand your knowledge or relax your mind",
                "pray": "Pray and reflect spiritually",
                "study": "Study to sharpen your understanding and skills",
                "walk": "Go for a walk to refresh your body and mind",
                "run": "Go for a run to build endurance and strength"
            ]

            for (activity, days) in selectedActivities {
                if days.contains(dayIndex) {
                    let name = activity.capitalized
                    let desc = activityDescriptions[activity.lowercased()] ?? "Complete your \(activity.lowercased()) activity"
                    newTasks.append(TaskItem(
                        id: idForTask(name: name, description: desc, day: dateStr),
                        name: name,
                        description: desc,
                        xp: 40,
                        expiresInHours: 12,
                        internalType: "Set Day",
                        skillTargets: activitySkillMap[activity.lowercased()] ?? ["Discipline"]
                    ))
                }
            }
        }

        // --- Social tasks ---
        let weekday = Calendar.current.component(.weekday, from: date)

        newTasks.append(TaskItem(
            id: idForTask(name: "Social Interaction", description: "Have a meaningful conversation today", day: dateStr),
            name: "Social Interaction",
            description: "Have a meaningful conversation today",
            xp: 40,
            expiresInHours: 24,
            internalType: "Daily",
            skillTargets: ["Network"]
        ))

        if weekday == 7 {
            newTasks.append(TaskItem(
                id: idForTask(name: "Meet Someone New", description: "Talk to or meet someone new today", day: dateStr),
                name: "Meet Someone New",
                description: "Talk to or meet someone new today",
                xp: 60,
                expiresInHours: 24,
                internalType: "Set Day",
                skillTargets: ["Network"]
            ))
        }

        // --- Addiction-based Task ---
        if let addiction = data["majorFocus"] as? String,
           !addiction.isEmpty,
           let severity = data["addictionDaysPerWeek"] as? Int {
            let cappedSeverity = max(1, min(severity, 7))
            let addTodayIndex = Calendar.current.component(.weekday, from: date)
            let normalizedDay = (addTodayIndex == 1) ? 7 : (addTodayIndex - 1)

            var selectedDays: [Int] = []
            switch cappedSeverity {
            case 7: selectedDays = [1, 2, 3, 4, 5, 6, 7]
            case 6: selectedDays = [1, 2, 3, 4, 5, 6]
            case 5: selectedDays = [1, 2, 3, 4, 5]
            case 4: selectedDays = [1, 2, 3, 4]
            case 3: selectedDays = [1, 3, 5]
            case 2: selectedDays = [2, 5]
            case 1: selectedDays = [3]
            default: selectedDays = []
            }

            if selectedDays.contains(normalizedDay) {
                newTasks.append(TaskItem(
                    id: idForTask(name: "Overcome \(addiction.capitalized)", description: "Take a step today to reduce your \(addiction.lowercased()) habit.", day: dateStr),
                    name: "Overcome \(addiction.capitalized)",
                    description: "Take a step today to reduce your \(addiction.lowercased()) habit.",
                    xp: 60,
                    expiresInHours: 12,
                    internalType: "Addiction",
                    skillTargets: ["Resilience", "Fuel", "Fitness", "Wisdom", "Discipline", "Network"]
                ))
            }
        }

        return newTasks
    }

    private func generateTasks(from data: [String: Any]) {
        let tasks = makeTasks(from: data, date: Date())
        self.assignedTasks = tasks.sorted { $0.name < $1.name }
        self.todayTotalPossibleXP = tasks.reduce(0) { $0 + $1.xp }
    }
    
    // Deterministic ID generator for a task for the given day (so same id across reloads)
    private func idForTask(name: String, description: String, day: String) -> String {
        // use a simple deterministic composite key; Firestore stores it verbatim
        // safe characters only: base64-ish could be used, but we keep it readable
        // format: day|name|description
        // day format is yyyy-MM-dd via dateStringForIDs()
        let raw = "\(day)|\(name)|\(description)"
        return raw // stored as string ID
    }
    
    // MARK: - Complete / Partial handling (persistence + XP)
    private func markComplete(_ task: TaskItem) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        completeTask(task, partial: false)
    }
    
    private func markPartial(_ task: TaskItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        completeTask(task, partial: true)
    }

    private func completeTask(_ task: TaskItem, partial: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        let assignedIDs = Set(assignedTasks.map { $0.id })
        let todayStr = isoDateString(from: Date())
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        let yesterdayStr = isoDateString(from: yesterday)

        userRef.firestore.runTransaction({ transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(userRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = snapshot.data() ?? [:]
            var completed = data["completedTasks"] as? [String] ?? []
            if completed.contains(task.id) {
                let existingTotal = normalizeSkillsMap(data["skills"]).values.compactMap { $0["xp"] }.reduce(0, +)
                return ["completed": completed, "streak": data["streak"] as? Int ?? 0, "totalSkillXP": existingTotal]
            }
            completed.append(task.id)

            var skills = normalizeSkillsMap(data["skills"])
            let targets = (task.skillTargets?.isEmpty == false) ? (task.skillTargets ?? allSkillNames) : allSkillNames
            let totalXP = partial ? max(0, Int(floor((Double(task.xp) / 2.0) / 5.0)) * 5) : task.xp
            let basePerSkill = totalXP / max(targets.count, 1)
            var remainder = totalXP % max(targets.count, 1)

            var taskSkillXP: [String: Int] = [:]
            for key in targets {
                var entry = skills[key] ?? ["level": 1, "xp": 0]
                let current = entry["xp"] ?? 0
                let add = basePerSkill + (remainder > 0 ? 1 : 0)
                if remainder > 0 { remainder -= 1 }
                taskSkillXP[key] = add
                let updatedXP = current + add
                entry["xp"] = updatedXP
                entry["level"] = calculateSkillLevel(from: updatedXP)
                skills[key] = entry
            }

            let totalSkillXP = skills.values.compactMap { $0["xp"] }.reduce(0, +)

            var todaySkillXP = data["todaySkillXP"] as? [String: Int] ?? [:]
            for (key, add) in taskSkillXP {
                todaySkillXP[key] = (todaySkillXP[key] ?? 0) + add
            }
            var todayTaskDetails = data["todayCompletedTaskDetails"] as? [[String: Any]] ?? []
            todayTaskDetails.append([
                "id": task.id,
                "name": task.name,
                "skillXP": taskSkillXP,
                "partial": partial
            ])

            var updates: [String: Any] = [
                "skills": skills,
                "xp": totalSkillXP,
                "completedTasks": completed,
                "todaySkillXP": todaySkillXP,
                "todayCompletedTaskDetails": todayTaskDetails
            ]

            let completedSet = Set(completed)
            if !assignedIDs.isEmpty, assignedIDs.isSubset(of: completedSet) {
                let lastStreakDate = data["lastStreakDate"] as? String ?? ""
                var currentStreak = data["streak"] as? Int ?? 0
                if lastStreakDate == yesterdayStr || lastStreakDate.isEmpty {
                    currentStreak += 1
                    updates["streak"] = currentStreak
                    updates["lastStreakDate"] = todayStr
                    let longest = data["longestStreak"] as? Int ?? 0
                    if currentStreak > longest {
                        updates["longestStreak"] = currentStreak
                    }
                }
            }

            transaction.updateData(updates, forDocument: userRef)
            let resultStreak = updates["streak"] as? Int ?? (data["streak"] as? Int ?? 0)
            return ["completed": completed, "streak": resultStreak, "taskSkillXP": taskSkillXP, "totalSkillXP": totalSkillXP]
        }) { result, error in
            guard error == nil, let payload = result as? [String: Any] else { return }
            if let completed = payload["completed"] as? [String] {
                DispatchQueue.main.async {
                    completedTaskIDs = completed
                    if let newStreak = payload["streak"] as? Int {
                        streak = newStreak
                    }
                    if let skillXP = payload["taskSkillXP"] as? [String: Int] {
                        var current = self.userData["todaySkillXP"] as? [String: Int] ?? [:]
                        for (key, add) in skillXP {
                            current[key] = (current[key] ?? 0) + add
                        }
                        self.userData["todaySkillXP"] = current
                    }
                    checkRankUp(totalSkillXP: payload["totalSkillXP"] as? Int ?? 0)
                }
            }
        }
    }

    private func undoCompleteTask(_ task: TaskItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)

        userRef.firestore.runTransaction({ transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(userRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let data = snapshot.data() ?? [:]
            let completed = data["completedTasks"] as? [String] ?? []
            guard completed.contains(task.id) else { return nil }

            let todayTaskDetails = data["todayCompletedTaskDetails"] as? [[String: Any]] ?? []
            guard let detailIdx = todayTaskDetails.firstIndex(where: { ($0["id"] as? String) == task.id }),
                  let taskSkillXP = todayTaskDetails[detailIdx]["skillXP"] as? [String: Int] else {
                return nil
            }

            var mutableCompleted = completed
            mutableCompleted.removeAll { $0 == task.id }

            var mutableDetails = todayTaskDetails
            mutableDetails.remove(at: detailIdx)

            var skills = normalizeSkillsMap(data["skills"])
            for (key, add) in taskSkillXP {
                guard var entry = skills[key] else { continue }
                let current = entry["xp"] ?? 0
                let newXP = max(0, current - add)
                entry["xp"] = newXP
                entry["level"] = calculateSkillLevel(from: newXP)
                skills[key] = entry
            }

            let totalSkillXP = skills.values.compactMap { $0["xp"] }.reduce(0, +)

            var todaySkillXP = data["todaySkillXP"] as? [String: Int] ?? [:]
            for (key, add) in taskSkillXP {
                let current = todaySkillXP[key] ?? 0
                let newToday = max(0, current - add)
                if newToday == 0 {
                    todaySkillXP.removeValue(forKey: key)
                } else {
                    todaySkillXP[key] = newToday
                }
            }

            transaction.updateData([
                "skills": skills,
                "xp": totalSkillXP,
                "completedTasks": mutableCompleted,
                "todaySkillXP": todaySkillXP,
                "todayCompletedTaskDetails": mutableDetails
            ], forDocument: userRef)

            return ["completed": mutableCompleted, "taskSkillXP": taskSkillXP]
        }) { result, error in
            guard error == nil, let payload = result as? [String: Any] else { return }
            if let completed = payload["completed"] as? [String] {
                DispatchQueue.main.async {
                    completedTaskIDs = completed
                    if let skillXP = payload["taskSkillXP"] as? [String: Int] {
                        var current = self.userData["todaySkillXP"] as? [String: Int] ?? [:]
                        for (key, add) in skillXP {
                            current[key] = max(0, (current[key] ?? 0) - add)
                            if current[key] == 0 { current.removeValue(forKey: key) }
                        }
                        self.userData["todaySkillXP"] = current
                    }
                }
            }
        }
    }

    private func normalizeSkillsMap(_ any: Any?) -> [String: [String: Int]] {
        guard let raw = any as? [String: Any] else { return [:] }
        var result: [String: [String: Int]] = [:]
        for (key, value) in raw {
            guard let entry = value as? [String: Any] else { continue }
            let xp = entry["xp"] as? Int ?? 0
            let level = entry["level"] as? Int ?? calculateSkillLevel(from: xp)
            result[key] = ["xp": xp, "level": level]
        }
        return result
    }
    
    private func resetStreakInFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        streak = 0
        Firestore.firestore().collection("users").document(uid)
            .updateData(["streak": 0])
    }
    
    private func checkRankUp(totalSkillXP: Int) {
        let computedRank = ranks.last(where: { Double(totalSkillXP) >= $0.requiredXP }) ?? ranks[0]
        if computedRank.id > lastRankId {
            if let oldRank = ranks.first(where: { $0.id == lastRankId }), lastRankId > 0 {
                celebrationPrevRank = oldRank
            }
            celebrationRank = computedRank
            showCelebration = true
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        lastRankId = computedRank.id
    }

    private func handleStreakContinuity(using data: [String: Any]) {
        guard let lastStreakDateStr = data["lastStreakDate"] as? String else {
            return
        }
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        let yesterdayStr = isoDateString(from: yesterday)
        let todayStr = isoDateString(from: Date())
        
        if lastStreakDateStr != yesterdayStr && lastStreakDateStr != todayStr {
            // broken
            resetStreakInFirestore()
        }
    }
    
    // MARK: - Midnight reset logic
    private func checkForMidnightReset() {
        let today = isoDateString(from: Date())
        if lastResetDate != today {
            let previousDate = lastResetDate
            lastResetDate = today
            completedTaskIDs.removeAll()
            if let uid = Auth.auth().currentUser?.uid {
                let userRef = Firestore.firestore().collection("users").document(uid)
                userRef.getDocument { snapshot, _ in
                    guard let data = snapshot?.data() else {
                        userRef.updateData(["completedTasks": [], "todaySkillXP": [:], "todayCompletedTaskDetails": []])
                        self.fetchUserData()
                        return
                    }
                    let skillXP = data["todaySkillXP"] as? [String: Int] ?? [:]
                    let completedCount = (data["completedTasks"] as? [String])?.count ?? 0
                    let xpGained = skillXP.values.reduce(0, +)

                    if !previousDate.isEmpty, completedCount > 0 || xpGained > 0 {
                        let logRef = userRef.collection("dailyLogs").document(previousDate)

                        let prevTotalXP: Int = {
                            let fmt = DateFormatter()
                            fmt.dateFormat = "yyyy-MM-dd"
                            guard let prevDate = fmt.date(from: previousDate) else { return 0 }
                            return self.makeTasks(from: data, date: prevDate).reduce(0) { $0 + $1.xp }
                        }()

                        logRef.setData([
                            "date": previousDate,
                            "completedCount": completedCount,
                            "xpGained": xpGained,
                            "totalPossibleXP": prevTotalXP,
                            "skillXP": skillXP,
                            "streak": data["streak"] as? Int ?? 0,
                            "timestamp": FieldValue.serverTimestamp()
                        ], merge: true)
                    }

                    userRef.updateData([
                        "completedTasks": [],
                        "todaySkillXP": [:],
                        "todayCompletedTaskDetails": []
                    ]) { _ in self.fetchUserData() }
                }
            } else {
                fetchUserData()
            }
        }
    }
    
    // Helper: coerce various Firestore array types to [Int]
    private func intArray(from any: Any?) -> [Int] {
        guard let arr = any as? [Any] else { return [] }
        return arr.compactMap { val in
            if let n = val as? Int { return n }
            if let n = val as? NSNumber { return n.intValue }
            if let s = val as? String, let i = Int(s) { return i }
            return nil
        }
    }

}

// MARK: - Date & time helpers
extension LoggingView {
    private func isoDateString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone.current
        return fmt.string(from: date)
    }
    
    func timeRemainingString() -> String {
        let now = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) else { return "0m" }
        let midnight = Calendar.current.startOfDay(for: tomorrow)
        let diff = Int(midnight.timeIntervalSince(now))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        return hours >= 1 ? "\(hours)h" : "\(minutes)m"
    }

    func hoursUntilMidnight() -> Int {
        let now = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) else { return 0 }
        let midnight = Calendar.current.startOfDay(for: tomorrow)
        let diff = Int(midnight.timeIntervalSince(now))
        return diff / 3600
    }
    
    // date used inside IDs - same format
    private func dateStringForIDs(from date: Date) -> String {
        return isoDateString(from: date)
    }
    
    private func timeFromMilitaryInt(_ intTime: Int) -> Date? {
        let hour = intTime / 100
        let minute = intTime % 100
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        // returns a date today at that time (used for formatting)
        return Calendar.current.date(from: comps)
    }
    
    private func formattedTime(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
    
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let gradient: LinearGradient
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(gradient, style: .init(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Task Card View
struct TaskCard: View {
    let task: TaskItem
    let isCompleted: Bool
    let isExpanded: Bool
    let accentGradient: LinearGradient
    let onTap: (() -> Void)?
    let onComplete: (() -> Void)?
    let onPartial: (() -> Void)?
    let onUndo: (() -> Void)?
    let timeRemaining: String

    private var categoryColor: Color {
        switch task.internalType {
        case "Daily": return Color(red: 84/255, green: 0/255, blue: 232/255)
        case "Set Day": return Color(red: 0/255, green: 122/255, blue: 255/255)
        case "Addiction": return Color.orange
        default: return .gray
        }
    }

    private var urgencyColor: Color {
        if timeRemaining.hasSuffix("h") {
            let hours = Int(timeRemaining.dropLast()) ?? 0
            if hours < 3 { return .red }
            if hours < 6 { return .yellow }
        }
        return .green
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconForName(task.name))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentGradient)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center) {
                        Text(task.internalType)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(categoryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.15))
                            .clipShape(Capsule())

                        Spacer()

                        Text("+\(task.xp) XP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accentGradient)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentGradient.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text(task.name)
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(task.description)
                        .foregroundColor(.white.opacity(0.55))
                        .font(.system(size: 12))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(urgencyColor)
                        Text(timeRemaining + " left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(urgencyColor)

                        Spacer()

                        if isCompleted {
                            Button { onUndo?() } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.system(size: 9))
                                    Text("Undo")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.07))
                                .clipShape(Capsule())
                            }
                        } else {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.07))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if isExpanded && !isCompleted {
                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.horizontal, 14)

                HStack(spacing: 10) {
                    Button(action: { onComplete?() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Mark Complete")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(AnyShapeStyle(accentGradient), lineWidth: 1.5)
                        )
                    }

                    Button(action: { onPartial?() }) {
                        Text("Partial")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isCompleted ? Color.green.opacity(0.2) : Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(isCompleted ? 0.6 : 1)
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isCompleted {
                Button { onComplete?() } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .tint(.green)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isCompleted {
                Button { onPartial?() } label: {
                    Label("Partial", systemImage: "star.leadinghalf.filled")
                }
                .tint(.orange)
            }
        }
        .onTapGesture { onTap?() }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isExpanded)
    }

    private func iconForName(_ name: String) -> String {
        let lower = name.lowercased()
        switch lower {
        case "arise and shine":   return "sunrise.fill"
        case "bedtime":           return "moon.zzz.fill"
        case "water intake":      return "drop.fill"
        case "screen time limit": return "iphone"
        case "workout":           return "figure.strengthtraining.traditional"
        case "cold shower":       return "snowflake"
        case "meditation":        return "brain.head.profile"
        case "reading":           return "book.fill"
        case "pray":              return "hands.sparkles.fill"
        case "study":             return "graduationcap.fill"
        case "walk":              return "figure.walk"
        case "run":               return "figure.run"
        case "social interaction": return "bubble.left.and.bubble.right.fill"
        case "meet someone new":  return "person.2.fill"
        case let str where str.contains("porn"):                                   return "eye.slash.fill"
        case let str where str.contains("screentime") || str.contains("screen time"): return "iphone"
        case let str where str.contains("vaping") || str.contains("smoking"):      return "smoke.fill"
        case let str where str.contains("alcohol"):                                return "wineglass.fill"
        case let str where str.contains("gaming"):                                 return "gamecontroller.fill"
        default: return lower.contains("overcome") ? "bolt.heart.fill" : "star.circle.fill"
        }
    }
}
