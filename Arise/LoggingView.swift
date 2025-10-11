import SwiftUI
import Firebase
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
    let internalType: String // "Daily" or "Set Day"
    
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
    
    // Timer to check for midnight (fires every minute)
    private let midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    enum TabOption: String, CaseIterable {
        case assigned = "Assigned"
        case completed = "Completed"
    }
    
    // aesthetic gradient
    private var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                        Color(red: 236/255, green: 71/255, blue: 1/255)]),
            startPoint: .leading,
            endPoint: .trailing
        )
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
                        VStack(spacing: 18) {
                            // --- Header (part of scroll content now) ---
                            headerView
                            
                            // --- Tabs (scrolls with content) ---
                            tabsView
                            
                            // subtle divider
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal)
                            
                            // --- Task list ---
                            VStack(spacing: 14) {
                                if selectedTab == .assigned {
                                    if visibleAssignedTasks.isEmpty {
                                        emptyStateView(title: "All assigned tasks have been completed.", subtitle: "Great work! — you have nothing let on the list!")
                                    } else {
                                        ForEach(visibleAssignedTasks) { task in
                                            TaskCard(
                                                task: task,
                                                isCompleted: false,
                                                isExpanded: expandedTaskID == task.id,
                                                accentGradient: accentGradient,
                                                onTap: { toggleExpand(task) },
                                                onComplete: { markComplete(task) },
                                                onPartial: { markPartial(task) }
                                            )
                                        }
                                    }
                                } else { // completed
                                    let completed = completedTasks
                                    if completed.isEmpty {
                                        emptyStateView(title: "No tasks completed", subtitle: "Finish tasks to see them here.")
                                    } else {
                                        ForEach(completed) { task in
                                            TaskCard(
                                                task: task,
                                                isCompleted: true,
                                                isExpanded: false,
                                                accentGradient: accentGradient,
                                                onTap: nil,
                                                onComplete: nil,
                                                onPartial: nil
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 60)
                        }
                        .padding(.top, 22)
                    }
                    .scrollIndicators(.hidden)
                    // Live timer to check for midnight while app is open
                    .onReceive(midnightTimer) { _ in
                        checkForMidnightReset()
                    }
                    // Refresh when app comes to foreground
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi, \(userName)")
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                
                Text("Here’s your day — I believe in you.")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.subheadline)
            }
            Spacer()
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 70, height: 44)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(accentGradient)
                        Text("\(streak)")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tabs
    private var tabsView: some View {
        HStack(spacing: 12) {
            ForEach(TabOption.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                        expandedTaskID = nil
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(colors: [Color.white, Color.white.opacity(0.85)],
                                                             startPoint: .top,
                                                             endPoint: .bottom))
                                        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 4)
                                        .matchedGeometryEffect(id: "tabBackground", in: tabAnimation)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                }
                            }
                        )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty state
    private func emptyStateView(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
            Text(subtitle)
                .foregroundColor(.white.opacity(0.65))
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Toggle Expand (fixed)
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
            print("No user logged in")
            isLoading = false
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Firestore fetch error:", error.localizedDescription)
                DispatchQueue.main.async { isLoading = false }
                return
            }
            guard let data = snapshot?.data() else {
                print("No user data")
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
                self.isLoading = false
            }
        }
    }
    
    private func generateTasks(from data: [String: Any]) {
        var newTasks: [TaskItem] = []
        let calendar = Calendar.current
        let todaySystem = calendar.component(.weekday, from: Date()) // Sunday=1 ... Saturday=7
        let todayIndex = (todaySystem == 1) ? 7 : (todaySystem - 1) // 1=Monday ... 7=Sunday
        let isWeekend = (todayIndex == 6 || todayIndex == 7)
        let todayStr = dateStringForIDs(from: Date())
        
        // --- Daily: wake / sleep ---
        if let wakeInt = data[isWeekend ? "wakeWeekend" : "wakeWeekday"] as? Int,
           let sleepHours = data[isWeekend ? "sleepHoursWeekend" : "sleepHoursWeekday"] as? Double {
            if let wakeDate = timeFromMilitaryInt(wakeInt),
               let bedtime = calculateBedtime(wakeTime: wakeDate, sleepHours: sleepHours) {
                let wakeReadable = formattedTime(from: wakeDate)
                let wakeName = "Wake Up"
                let wakeDesc = "Wake up at \(wakeReadable)"
                let wakeID = idForTask(name: wakeName, description: wakeDesc, day: todayStr)
                newTasks.append(TaskItem(id: wakeID, name: wakeName, description: wakeDesc, xp: 25, expiresInHours: 6, internalType: "Daily"))
                
                let sleepName = "Sleep"
                let sleepDesc = "Sleep by \(bedtime)"
                let sleepID = idForTask(name: sleepName, description: sleepDesc, day: todayStr)
                newTasks.append(TaskItem(id: sleepID, name: sleepName, description: sleepDesc, xp: 25, expiresInHours: 12, internalType: "Daily"))
            }
        }
        
        // --- Daily: water & screen ---
        if let water = data["waterOunces"] as? Int {
            let name = "Drink Water"
            let desc = "Drink \(water) oz of water today"
            let id = idForTask(name: name, description: desc, day: todayStr)
            newTasks.append(TaskItem(id: id, name: name, description: desc, xp: 20, expiresInHours: 10, internalType: "Daily"))
        }
        
        if let screenLimit = data["screenLimitHours"] as? Int {
            let name = "Screen Time Limit"
            let desc = "Stay under \(screenLimit) hours of screen time"
            let id = idForTask(name: name, description: desc, day: todayStr)
            newTasks.append(TaskItem(id: id, name: name, description: desc, xp: 20, expiresInHours: 10, internalType: "Daily"))
        }
        
        // --- Set-day: workouts ---
        let workoutDays = intArray(from: data["workoutDays"])
        if workoutDays.contains(todayIndex),
           let workoutHoursAny = data["workoutHoursPerDay"] {
            let workoutHours: Int
            if let intVal = workoutHoursAny as? Int { workoutHours = intVal }
            else if let n = workoutHoursAny as? NSNumber { workoutHours = n.intValue }
            else if let s = workoutHoursAny as? String, let i = Int(s) { workoutHours = i }
            else { workoutHours = 0 }

            if workoutHours > 0 {
                let minutes = workoutHours * 60
                let name = "Workout"
                let desc = "Workout for \(minutes) minutes"
                let id = idForTask(name: name, description: desc, day: todayStr)
                newTasks.append(TaskItem(id: id, name: name, description: desc, xp: 50, expiresInHours: 12, internalType: "Set Day"))
            }
        }

        // --- Set-day: Cold Showers ---
        let coldDays = intArray(from: data["coldShowerDays"])
        if coldDays.contains(todayIndex) {
            let name = "Cold Shower"
            let desc = "Take a cold shower"
            let id = idForTask(name: name, description: desc, day: todayStr)
            newTasks.append(TaskItem(
                id: id,
                name: name,
                description: desc,
                xp: 35,
                expiresInHours: 12,
                internalType: "Set Day"
            ))
        }
        
        // --- Set-day: custom selectedActivities (map name -> [Int]) ---
        if let selectedActivities = data["selectedActivities"] as? [String: [Int]] {
            for (activity, days) in selectedActivities {
                if days.contains(todayIndex) {
                    let name = activity.capitalized
                    let desc = "Complete your \(activity.lowercased()) activity"
                    let id = idForTask(name: name, description: desc, day: todayStr)
                    newTasks.append(TaskItem(id: id, name: name, description: desc, xp: 30, expiresInHours: 12, internalType: "Set Day"))
                }
            }
        }
        
        // Assign tasks sorted (optional: by type then name for consistency)
        self.assignedTasks = newTasks.sorted { $0.name < $1.name }
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
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Apply full XP and persist completed ID
        performXPDistribution(for: task, partial: false) { success in
            if success {
                persistTaskCompletion(taskID: task.id, uid: uid)
            } else {
                // handle error (omitted UI toast)
            }
        }
    }
    
    private func markPartial(_ task: TaskItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Apply partial XP and persist completed ID
        performXPDistribution(for: task, partial: true) { success in
            if success {
                persistTaskCompletion(taskID: task.id, uid: uid)
            } else {
                // handle error
            }
        }
    }
    
    // Add taskID to completedTaskIDs and update Firestore
    private func persistTaskCompletion(taskID: String, uid: String) {
        // prevent duplicates
        if !completedTaskIDs.contains(taskID) {
            completedTaskIDs.append(taskID)
        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.updateData(["completedTasks": completedTaskIDs]) { err in
            if let err = err {
                print("Error persisting completedTasks:", err.localizedDescription)
            } else {
                // Move UI: no need to remove from assignedTasks since we compute visibleAssignedTasks
                // check streak increment
                checkAndIncrementStreakIfAllDone(uid: uid)
            }
        }
    }
    
    // Check if all assigned tasks are completed; if so, increment streak and set lastStreakDate
    private func checkAndIncrementStreakIfAllDone(uid: String) {
        // all assigned tasks' ids should be subset of completedTaskIDs
        let assignedIDs = Set(assignedTasks.map { $0.id })
        let completedSet = Set(completedTaskIDs)
        if assignedIDs.isSubset(of: completedSet) && !assignedIDs.isEmpty {
            // increment streak once
            incrementStreak(uid: uid)
        }
    }
    
    // XP distribution: modifies skills map in Firestore
    private func performXPDistribution(for task: TaskItem, partial: Bool, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        userRef.getDocument { snapshot, err in
            if let err = err {
                print("Error fetching user doc for XP:", err.localizedDescription)
                completion(false)
                return
            }
            guard let data = snapshot?.data() else {
                print("No user doc")
                completion(false)
                return
            }
            
            var skillsMap = (data["skills"] as? [String: Any]) ?? [:]
            // order to distribute remainders consistently
            let skillKeys = ["Resilience", "Fuel", "Fitness", "Wisdom", "Discipline", "Network"]
            
            let totalXP = task.xp
            let effectiveTotal: Int
            if partial {
                // half, round down to nearest 5
                let half = Double(totalXP) / 2.0
                let halfRoundedDownTo5 = Int(floor(half / 5.0)) * 5
                effectiveTotal = max(0, halfRoundedDownTo5)
            } else {
                effectiveTotal = totalXP
            }
            
            // distribute
            let basePerSkill = effectiveTotal / skillKeys.count
            var remainder = effectiveTotal % skillKeys.count
            
            for key in skillKeys {
                var entry = (skillsMap[key] as? [String: Any]) ?? [:]
                let existingXP = (entry["xp"] as? Int) ?? 0
                
                var add = basePerSkill
                if remainder > 0 {
                    add += 1
                    remainder -= 1
                }
                entry["xp"] = existingXP + add
                // preserve level if exists
                skillsMap[key] = entry
            }
            
            userRef.updateData(["skills": skillsMap]) { updateErr in
                if let updateErr = updateErr {
                    print("Error updating skills:", updateErr.localizedDescription)
                    completion(false)
                    return
                } else {
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Streak helpers
    private func incrementStreak(uid: String) {
        streak += 1
        let todayStr = isoDateString(from: Date())
        Firestore.firestore().collection("users").document(uid)
            .updateData(["streak": streak, "lastStreakDate": todayStr]) { err in
                if let err = err {
                    print("Error updating streak:", err.localizedDescription)
                }
            }
    }
    
    private func resetStreakInFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        streak = 0
        Firestore.firestore().collection("users").document(uid)
            .updateData(["streak": 0]) { err in
                if let err = err {
                    print("Error resetting streak:", err.localizedDescription)
                }
            }
    }
    
    private func handleStreakContinuity(using data: [String: Any]) {
        guard let lastStreakDateStr = data["lastStreakDate"] as? String else {
            return
        }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
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
            lastResetDate = today
            // clear local completed list and clear persisted completed in Firestore
            completedTaskIDs.removeAll()
            // clear Firestore completedTasks for today (so UI resets for next day)
            if let uid = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("users").document(uid)
                    .updateData(["completedTasks": []]) { err in
                        if let err = err {
                            print("Error clearing completedTasks on midnight reset:", err.localizedDescription)
                        } else {
                            // Also refresh user data after clearing server-side completed tasks
                            fetchUserData()
                        }
                    }
            } else {
                // If no uid, still regenerate tasks locally
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

    // Helper: coerce possible bool-like Firestore values to Bool
    private func boolValue(from any: Any?) -> Bool {
        if let b = any as? Bool { return b }
        if let n = any as? NSNumber { return n.boolValue }
        if let s = any as? String {
            let lower = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return lower == "true" || lower == "1" || lower == "yes"
        }
        return false
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
    
    // Bedtime calculator (exactly as you gave)
    private func calculateBedtime(wakeTime: Date, sleepHours: Double) -> String? {
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
}

// MARK: - Task Card View (visual)
struct TaskCard: View {
    let task: TaskItem
    let isCompleted: Bool
    let isExpanded: Bool
    let accentGradient: LinearGradient
    let onTap: (() -> Void)?
    let onComplete: (() -> Void)?
    let onPartial: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                // icon circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 56, height: 56)
                    Image(systemName: iconForName(task.name))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accentGradient)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.name)
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        if isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    
                    Text(task.description)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
            
            HStack {
                HStack(spacing: 8) {
                    Text("+\(task.xp) XP")
                        .font(.caption2).bold()
                        .foregroundStyle(accentGradient)
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 2, height: 18)
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(task.expiresInHours)h")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
                // chevron for expand if not completed
                if !isCompleted {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // expanded action buttons
            if isExpanded && !isCompleted {
                HStack(spacing: 12) {
                    Button(action: { onComplete?() }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Mark Complete")
                        }
                        .font(.subheadline.bold())
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(accentGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { onPartial?() }) {
                        Text("Partial")
                            .font(.subheadline.bold())
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.03))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 6)
        .onTapGesture {
            onTap?()
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isExpanded)
    }
    
    private func iconForName(_ name: String) -> String {
        switch name {
        case "Wake Up": return "sunrise.fill"
        case "Sleep": return "bed.double.fill"
        case "Drink Water": return "drop.fill"
        case "Screen Time Limit": return "sparkles"
        case "Workout": return "figure.strengthtraining.traditional"
        case "Cold Shower": return "thermometer.snowflake"
        default: return "sparkles"
        }
    }
}
