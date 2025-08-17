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

    var filteredTasks: [Task] {
        switch selectedFilter {
        case .skill:
            return tasks.sorted { $0.skill < $1.skill }
        case .expiry:
            return tasks.sorted { $0.expiresInHours < $1.expiresInHours }
        case .xp:
            return tasks.sorted { $0.xp > $1.xp }
        case .none:
            return tasks.sorted { $0.expiresInHours < $1.expiresInHours }
        }
    }

    let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 84/255, green: 0/255, blue: 232/255),
            Color(red: 236/255, green: 71/255, blue: 1/255)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    HStack {
                        Text("Tasks")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Spacer()

                        Menu {
                            ForEach(FilterOption.allCases) { option in
                                Button(action: {
                                    selectedFilter = option
                                }) {
                                    HStack {
                                        Text(option.rawValue)
                                        Spacer()
                                        if selectedFilter == option {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(gradient)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.title2)
                            }
                            .font(.headline)
                            .foregroundStyle(gradient)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredTasks) { task in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(task.name)
                                            .foregroundColor(.white)
                                            .font(.headline)

                                        Text("Trains: \(task.skill)")
                                            .foregroundColor(.gray)
                                            .font(.caption)

                                        Text("Expires in \(task.expiresInHours)h")
                                            .foregroundColor(.gray)
                                            .font(.caption2)
                                    }

                                    Spacer()

                                    VStack {
                                        Text("\(task.xp) XP")
                                            .foregroundColor(.orange)
                                            .font(.subheadline.bold())
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
