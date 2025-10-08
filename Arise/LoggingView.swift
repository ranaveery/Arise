import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct Task: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let xp: Int
    let expiresInHours: Int
    let type: String // "Daily" or "Set Day"
    var isCompleted: Bool = false
}

struct LoggingView: View {
    @State private var userName: String = ""
    @State private var streak: Int = 0
    @State private var tasks: [Task] = []
    @State private var completedTasks: [Task] = []
    @State private var isLoading = true
    @State private var selectedTab: TabOption = .assigned
    @State private var userData: [String: Any] = [:]
    @AppStorage("lastResetDate") private var lastResetDate = ""
    
    enum TabOption: String, CaseIterable {
        case assigned = "Assigned"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading your day...")
                        .foregroundColor(.white)
                } else {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hi, \(userName)")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.white)
                                
                                Text("Let’s make today count.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Streak indicator
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("\(streak)")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .padding(.top, 40)
                        
                        // MARK: - Tabs
                        HStack(spacing: 12) {
                            ForEach(TabOption.allCases, id: \.rawValue) { tab in
                                Text(tab.rawValue)
                                    .font(.headline)
                                    .foregroundColor(selectedTab == tab ? .white : .gray)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedTab == tab ? Color.white.opacity(0.1) : Color.clear)
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            selectedTab = tab
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                        
                        // MARK: - Task List
                        ScrollView {
                            VStack(spacing: 14) {
                                if selectedTab == .assigned {
                                    if tasks.isEmpty {
                                        Text("No tasks assigned today 🎉")
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.top, 30)
                                    } else {
                                        ForEach(tasks) { task in
                                            TaskCard(task: task) {
                                                markTaskCompleted(task)
                                            }
                                        }
                                    }
                                } else {
                                    if completedTasks.isEmpty {
                                        Text("No tasks completed yet 💪")
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.top, 30)
                                    } else {
                                        ForEach(completedTasks) { task in
                                            TaskCard(task: task, isCompleted: true)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 80)
                        }
                        .scrollIndicators(.hidden)
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
}

// MARK: - Firestore Fetch and Task Logic
extension LoggingView {
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No user data found")
                isLoading = false
                return
            }
            
            DispatchQueue.main.async {
                self.userData = data
                self.userName = data["name"] as? String ?? "User"
                self.streak = data["streak"] as? Int ?? 0
                self.generateTasks(from: data)
                self.isLoading = false
            }
        }
    }
    
    private func generateTasks(from data: [String: Any]) {
        var newTasks: [Task] = []
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date()) // 1=Sunday ... 7=Saturday
        let convertedToday = today == 1 ? 7 : today - 1 // 1=Monday ... 7=Sunday
        
        let isWeekend = convertedToday == 6 || convertedToday == 7
        
        // MARK: Daily Tasks
        if let wakeInt = data[isWeekend ? "wakeWeekend" : "wakeWeekday"] as? Int,
           let sleepHours = data[isWeekend ? "sleepHoursWeekend" : "sleepHoursWeekday"] as? Double {
            
            if let wakeTime = timeFromMilitaryInt(wakeInt),
               let bedtimeString = calculateBedtime(wakeTime: wakeTime, sleepHours: sleepHours) {
                
                let wakeString = formattedTime(from: wakeTime)
                
                newTasks.append(Task(
                    name: "Wake Up",
                    description: "Wake up at \(wakeString)",
                    xp: 25,
                    expiresInHours: 6,
                    type: "Daily"
                ))
                
                newTasks.append(Task(
                    name: "Sleep",
                    description: "Sleep by \(bedtimeString)",
                    xp: 25,
                    expiresInHours: 12,
                    type: "Daily"
                ))
            }
        }
        
        if let waterOunces = data["waterOunces"] as? Int {
            newTasks.append(Task(
                name: "Drink Water",
                description: "Drink \(waterOunces) oz of water today",
                xp: 20,
                expiresInHours: 10,
                type: "Daily"
            ))
        }
        
        if let screenLimitHours = data["screenLimitHours"] as? Int {
            newTasks.append(Task(
                name: "Screen Time Limit",
                description: "Stay under \(screenLimitHours) hours of screen time",
                xp: 20,
                expiresInHours: 10,
                type: "Daily"
            ))
        }
        
        // MARK: Set-day Tasks
        if let workoutDays = data["workoutDays"] as? [Int],
           workoutDays.contains(convertedToday),
           let workoutDuration = data["workoutHoursPerDay"] as? Int {
            
            newTasks.append(Task(
                name: "Workout",
                description: "Workout for \(workoutDuration * 60) minutes",
                xp: 50,
                expiresInHours: 12,
                type: "Set Day"
            ))
        }
        
        if let coldShowers = data["takeColdShowers"] as? Bool, coldShowers,
           let coldDays = data["coldShowerDays"] as? [Int],
           coldDays.contains(convertedToday) {
            
            newTasks.append(Task(
                name: "Cold Shower",
                description: "Take a cold shower today",
                xp: 35,
                expiresInHours: 12,
                type: "Set Day"
            ))
        }
        
        if let selectedActivities = data["selectedActivities"] as? [String: [Int]] {
            for (activity, days) in selectedActivities {
                if days.contains(convertedToday) {
                    newTasks.append(Task(
                        name: activity.capitalized,
                        description: "Complete your \(activity.lowercased()) activity",
                        xp: 30,
                        expiresInHours: 12,
                        type: "Set Day"
                    ))
                }
            }
        }
        
        self.tasks = newTasks
    }
    
    private func markTaskCompleted(_ task: Task) {
        if let index = tasks.firstIndex(of: task) {
            var completedTask = tasks[index]
            completedTask.isCompleted = true
            tasks.remove(at: index)
            completedTasks.append(completedTask)
        }
        
        if tasks.isEmpty {
            incrementStreak()
        }
    }
    
    private func incrementStreak() {
        streak += 1
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["streak": streak])
    }
    
    private func resetStreak() {
        streak = 0
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["streak": 0])
    }
    
    private func checkForMidnightReset() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        if lastResetDate != today {
            lastResetDate = today
            completedTasks.removeAll()
            fetchUserData()
        }
    }
}

// MARK: - Helpers
extension LoggingView {
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
    
    private func timeFromMilitaryInt(_ intTime: Int) -> Date? {
        let hour = intTime / 100
        let minute = intTime % 100
        let components = DateComponents(hour: hour, minute: minute)
        return Calendar.current.date(from: components)
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: Task
    var isCompleted: Bool = false
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                if !isCompleted {
                    Button(action: {
                        onComplete?()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("+\(task.xp) XP")
                .font(.caption.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 84/255, green: 0/255, blue: 232/255),
                            Color(red: 236/255, green: 71/255, blue: 1/255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 84/255, green: 0/255, blue: 232/255),
                                    Color(red: 236/255, green: 71/255, blue: 1/255)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
        .opacity(isCompleted ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.25), value: isCompleted)
    }
}
