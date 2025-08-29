import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    let name: String
    let xp: Int
    let expiresInHours: Int
    let skill: String
}

struct LoggingView: View {
    @State private var selectedFilter: FilterOption? = nil
    
    // Track expansion state per skill
    @State private var expandedSkills: [String: Bool] = [
        "Resilience": true,
        "Wisdom": true,
        "Fuel": true,
        "Fitness": true,
        "Discipline": true,
        "Network": true
    ]
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case skill = "Skill"
        case expiry = "Time"
        case xp = "XP"

        var id: String { self.rawValue }
    }

    @State private var tasks: [Task] = [
        Task(name: "Meditate 10 mins", xp: 50, expiresInHours: 5, skill: "Resilience"),
        Task(name: "Read 20 pages", xp: 40, expiresInHours: 10, skill: "Wisdom"),
        Task(name: "Drink 2L water", xp: 25, expiresInHours: 3, skill: "Fuel"),
        Task(name: "Workout", xp: 60, expiresInHours: 6, skill: "Fitness"),
        Task(name: "No sugar today", xp: 35, expiresInHours: 4, skill: "Discipline"),
        Task(name: "Text 3 people", xp: 30, expiresInHours: 2, skill: "Network")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Title + subtitle
                        VStack(spacing: 4) {
                            Text("Tasks")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            
                            Text("Track and manage your progress")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        // Skills + tasks
                        VStack(spacing: 24) {
                            ForEach(["Resilience", "Wisdom", "Fuel", "Fitness", "Discipline", "Network"], id: \.self) { skill in
                                VStack(alignment: .leading, spacing: 12) {
                                    
                                    // Section header
                                    HStack(spacing: 8) {
                                        Image(systemName: iconForSkill(skill))
                                            .font(.system(size: 26))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 84/255, green: 0/255, blue: 232/255),
                                                        Color(red: 236/255, green: 71/255, blue: 1/255)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        
                                        Text(skill)
                                            .font(.title.bold())
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 84/255, green: 0/255, blue: 232/255),
                                                        Color(red: 236/255, green: 71/255, blue: 1/255)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        
                                        Image(systemName: expandedSkills[skill] ?? true ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            expandedSkills[skill]?.toggle()
                                        }
                                    }
                                    
                                    // Tasks in section
                                    if expandedSkills[skill] ?? true {
                                        VStack(spacing: 12) {
                                            ForEach(tasks.filter { $0.skill == skill }) { task in
                                                TaskCard(task: task)
                                                    .transition(.move(edge: .top).combined(with: .opacity))
                                            }
                                        }
                                        .animation(.easeInOut(duration: 0.3), value: expandedSkills[skill])
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func iconForSkill(_ skill: String) -> String {
        switch skill {
        case "Resilience": return "brain"
        case "Wisdom": return "book.fill"
        case "Fuel": return "fork.knife"
        case "Fitness": return "figure.run"
        case "Discipline": return "infinity"
        case "Network": return "person.2.fill"
        default: return "circle.fill"
        }
    }
}

// Task card
struct TaskCard: View {
    let task: Task
    let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 84/255, green: 0/255, blue: 232/255),
            Color(red: 236/255, green: 71/255, blue: 1/255)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    private var timeColor: Color {
        if task.expiresInHours < 3 {
            return .red
        } else if task.expiresInHours < 6 {
            return .yellow
        } else {
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.name)
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
                Text("+\(task.xp) XP")
                    .font(.headline.bold())
                    .foregroundStyle(gradient)
            }
            
            HStack {
                Label(task.skill, systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("\(task.expiresInHours)h")
                }
                .font(.caption2)
                .foregroundColor(timeColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(gradient, lineWidth: 1.2)
                )
        )
    }
}
