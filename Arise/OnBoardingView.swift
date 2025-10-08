import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - App Gradient (single source of truth)
private let appGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 84/255, green: 0/255, blue: 232/255),
        Color(red: 236/255, green: 71/255, blue: 1/255)
    ]),
    startPoint: .leading,
    endPoint: .trailing
)

private struct NavHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    // UI state
    @State private var currentStep: Int = 0
    @State private var navHeight: CGFloat = 0
    @State private var isSaving: Bool = false

    // --- Answers state ---
    // Intro has no inputs
    @State private var majorFocus: String = ""
    
    // Wake time (weekday/weekend)
    @State private var wakeWeekday: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeWeekend: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Sleep duration (hours)
    @State private var sleepHoursWeekday: Double = 8
    @State private var sleepHoursWeekend: Double = 9
    
    // Workout
    @State private var workoutHoursPerDay: Double = 1.0
    @State private var workoutDays: Set<Int> = []
    
    // Screen time
    @State private var screenLimitHours: Double = 3.0
    
    // Weight -> water
    @State private var weightLbs: Int = 140
    private var waterOunces: Int { Int((Double(weightLbs) * (2.0/3.0)).rounded()) }

    // Cold showers
    @State private var takeColdShowers: Bool = false
    @State private var coldShowerDays: Set<Int> = []
    
    // Extra activities
    let activityOptions = ["Meditation","Reading","Pray","Study","Walk","Run"]
    struct ActivityConfig {
        var frequency: Int
        var days: Set<Int>
    }
    @State private var selectedActivities: [String: ActivityConfig] = [:]

    // Revisit addictions severity
    @State private var addictionChoices: [String] = ["Screentime","Porn","Vaping","Smoking","Alcohol","Gaming"]
    @State private var selectedAddiction: String = ""
    @State private var addictionDaysPerWeek: Int = 3
    @State private var showAddictionSheet = false

    
    // Final overview note
    @State private var finalNote: String = ""
    
    // Completion callback
    let onFinish: () -> Void
    
    // total final step index (0..10 used in your original code)
    private let maxStepIndex = 10
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 18) {
                // --- Top bar: Back + Progress ---
                if currentStep > 0 {
                    topProgressBar
                }
                
                Spacer(minLength: 6)
                
                // Content
                stepView
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 12)
                
                // bottom navigation (keeps measured height)
                bottomNavigation
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: NavHeightPreferenceKey.self, value: proxy.size.height)
                        }
                    )
            }
            .padding(.top, 8)
        }
        .onPreferenceChange(NavHeightPreferenceKey.self) { navHeight = $0 }
        .animation(.easeInOut, value: currentStep)
    }
    
    // MARK: - Top Progress Bar + Back Button
    private var topProgressBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                SquareActionButton(icon: "chevron.left", action: {
                    withAnimation { currentStep = max(0, currentStep - 1) }
                })
                .frame(width: 48, height: 48)
            } else {
                // keep spacing consistent
                Color.clear.frame(width: 48, height: 48)
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 10)
                    
                    // filled bar
                    Capsule()
                        .fill(appGradient)
                        .frame(width: progressWidth(in: proxy.size.width), height: 10)
                        .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 2)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 24)
        }
        .padding(.horizontal)
    }
    
    private func progressWidth(in total: CGFloat) -> CGFloat {
        guard maxStepIndex > 0 else { return 0 }
        let percent = min(1.0, max(0.0, Double(currentStep) / Double(maxStepIndex)))
        return total * CGFloat(percent)
    }
    
    // MARK: - Step Views
    @ViewBuilder
    private var stepView: some View {
        switch currentStep {
        case 0: introStep
        case 1: majorFocusStep
        case 2: wakeTimeStep
        case 3: sleepDurationStep
        case 4: workoutStep
        case 5: screenTimeStep
        case 6: weightWaterStep
        case 7: coldShowerStep
        case 8: activitiesStep
        case 9: revisitAddictionStep
        case 10: overviewStep
        default: completionView
        }
    }
    
    // --- 0: Intro
    private var introStep: some View {
        VStack(spacing: 24) {
            Image("logo_arise")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .padding(.top, 20)
            
            Text("Let’s get to know you better")
                .font(.title2).bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            Text("Answer all questions honestly. We want to tailor you a perfect plan to Arise and become who you are destined to be.")
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .font(.footnote)
                .padding(.horizontal, 12)
        }
    }

    
    // --- 1: Major focus
    private var majorFocusStep: some View {
        VStack(spacing: 16) {
            // Question
            Text("What’s your main focus to improve?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 8)

            // Content grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(addictionChoices, id: \.self) { item in
                    OptionButton(text: item, isSelected: selectedAddiction == item) {
                        if selectedAddiction == item {
                            selectedAddiction = ""
                        } else {
                            selectedAddiction = item
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Sub-description (moved to bottom)
            Text("Choose an addiction/major habit you'd like to work on. We’ll come back to this and ask how severe it is.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }


    // --- 2: Wake times
    private var wakeTimeStep: some View {
        VStack(spacing: 24) {
            // Title
            Text("When do you wake up?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 8)

            // Subtitle
            Text("Set separate times for weekdays and weekends.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Cards
            HStack(spacing: 16) {
                // Weekdays
                VStack(spacing: 12) {
                    Text("Weekdays")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DatePicker("", selection: Binding(
                        get: { wakeWeekday },
                        set: { newValue in
                            wakeWeekday = roundToNearest15(newValue)
                        }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                .frame(width: 150)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)

                // Weekends
                VStack(spacing: 12) {
                    Text("Weekends")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DatePicker("", selection: Binding(
                        get: { wakeWeekend },
                        set: { newValue in
                            wakeWeekend = roundToNearest15(newValue)
                        }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                .frame(width: 150)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }



    
    // --- 3: Sleep duration
    private var sleepDurationStep: some View {
        VStack(spacing: 24) {
            // Title
            Text("Sleep Duration Goals")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 8)

            // Subtitle
            Text("Set different sleep goals for weekdays and weekends.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VStack(spacing: 24) {
                // --- Weekdays Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.white)
                        Text("Weekdays")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()

                        let hours = Int(sleepHoursWeekday)
                        let minutes = Int((sleepHoursWeekday - Double(hours)) * 60)
                        Text("\(hours)h\(minutes > 0 ? " \(minutes)m" : "")")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Slider(
                        value: Binding(
                            get: { sleepHoursWeekday },
                            set: { newValue in
                                // snap to nearest 0.25 hr (15 minutes)
                                let stepped = (newValue / 0.25).rounded() * 0.25
                                sleepHoursWeekday = min(max(6.0, stepped), 12.0)
                            }
                        ),
                        in: 6...12,
                        step: 0.01 // smooth but snaps via Binding
                    )
                    .tint(.gray)

                    if let bedtime = calculateBedtime(wakeTime: wakeWeekday, sleepHours: sleepHoursWeekday) {
                        Text("Suggested bedtime: **\(bedtime)**")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(18)

                // --- Weekends Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "bed.double.circle.fill")
                            .foregroundColor(.white)
                        Text("Weekends")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()

                        let hours = Int(sleepHoursWeekend)
                        let minutes = Int((sleepHoursWeekend - Double(hours)) * 60)
                        Text("\(hours)h\(minutes > 0 ? " \(minutes)m" : "")")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Slider(
                        value: Binding(
                            get: { sleepHoursWeekend },
                            set: { newValue in
                                // snap to nearest 0.25 hr (15 minutes)
                                let stepped = (newValue / 0.25).rounded() * 0.25
                                sleepHoursWeekend = min(max(6.0, stepped), 12.0)
                            }
                        ),
                        in: 6...12,
                        step: 0.01 // smooth but snaps via Binding
                    )
                    .tint(.gray)

                    if let bedtime = calculateBedtime(wakeTime: wakeWeekend, sleepHours: sleepHoursWeekend) {
                        Text("Suggested bedtime: **\(bedtime)**")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(18)
            }
            .padding(.horizontal)

            Spacer()

            // Tip
            Text("Good sleep improves focus, recovery, and energy — aim for consistency.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }


    private func roundToNearest15(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return date }

        // Round minutes to nearest 15
        let roundedMinute = Int((Double(minute) / 15.0).rounded() * 15) % 60
        let extraHour = (minute >= 53) ? 1 : 0

        return calendar.date(bySettingHour: hour + extraHour, minute: roundedMinute, second: 0, of: date) ?? date
    }
    
    // MARK: - Helper
    private func calculateBedtime(wakeTime: Date, sleepHours: Double) -> String? {
        let calendar = Calendar.current
        // Subtract full hours + minutes
        guard let bedtime = calendar.date(byAdding: .minute,
                                          value: Int(-sleepHours * 60),
                                          to: wakeTime) else { return nil }

        // Round to nearest 15 minutes
        let minutes = calendar.component(.minute, from: bedtime)
        let remainder = minutes % 15
        let adjustment = remainder < 8 ? -remainder : (15 - remainder)
        guard let roundedBedtime = calendar.date(byAdding: .minute,
                                                 value: adjustment,
                                                 to: bedtime) else { return nil }

        // Format result
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: roundedBedtime)
    }

    // --- 4: Workout preferences
    private var workoutStep: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Workout Preferences")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                Text("Set your weekly workout goals.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 24) {
                    // --- Hours per day card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.white)
                            Text("Duration per day")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            
                            let hours = Int(workoutHoursPerDay)
                            let minutes = Int((workoutHoursPerDay - Double(hours)) * 60)
                            Text("\(hours)h\(minutes > 0 ? " \(minutes)m" : "")")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { workoutHoursPerDay },
                                set: { newValue in
                                    // snap to nearest 0.25 hr (15 min)
                                    let stepped = (newValue / 0.25).rounded() * 0.25
                                    workoutHoursPerDay = min(max(0.5, stepped), 3.0) // 30 min – 3h
                                }
                            ),
                            in: 0.5...3.0,
                            step: 0.01
                        )
                        .tint(.gray)
                        
                        Text("Set how long you’d like to workout.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(appGradient, lineWidth: 2)
                    )
                    .cornerRadius(18)
                    
                    // --- Preferred days card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.white)
                            Text("Preferred Days")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        DaysOfWeekPicker(selection: $workoutDays)
                        
                        Text("Pick which days you’re most consistent.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(appGradient, lineWidth: 2)
                    )
                    .cornerRadius(18)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Consistency matters more than intensity — choose what you can stick to.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var screenTimeStep: some View {
        VStack(spacing: 28) {
            // --- Title + recommendation
            VStack(spacing: 6) {
                Text("Daily screen time limit")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("We recommend about 3 hours a day to maintain a balanced lifestyle.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 16)
            
            // --- Slider + comparison
            VStack(spacing: 16) {
                // --- Value row
                HStack {
                    Text("Daily limit")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    
                    let hours = Int(screenLimitHours)
                    let minutes = Int((screenLimitHours - Double(hours)) * 60)
                    let displayText = "\(hours)h" + (minutes > 0 ? " \(minutes)m" : "")
                    
                    Text(displayText)
                        .font(.headline)
                        .foregroundColor(
                            screenLimitHours == 3.0 ? .green :
                            (screenLimitHours > 3.5 ? .red : .white)
                        )
                }

                
                // --- Slider input
                Slider(
                    value: Binding(
                        get: { screenLimitHours },
                        set: { newValue in
                            // snap to nearest 0.25 hr (15 min)
                            let stepped = (newValue / 0.25).rounded() * 0.25
                            screenLimitHours = min(max(0.25, stepped), 6.0) // 15 min – 6h
                        }
                    ),
                    in: 0.25...6.0,
                    step: 0.01
                )
                .tint(.gray)
                
                // --- Comparison bar
                VStack(spacing: 6) {
                    ZStack(alignment: .leading) {
                        // Gradient background
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .yellow, .green, .red
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .clipShape(Capsule())
                        
                        // User marker
                        GeometryReader { geo in
                            let fraction = min(max(screenLimitHours / 6.0, 0), 1)
                            Circle()
                                .fill(.white)
                                .frame(width: 16, height: 16)
                                .offset(x: fraction * (geo.size.width - 16))
                        }
                    }
                    .frame(height: 16)
                    
                    // Ideal indicator
                    Text("Ideal: ~3h/day")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                // --- Text description
                Text(sliderDescription(for: Int(screenLimitHours * 60)))
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(appGradient, lineWidth: 2)
            )
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }


    // MARK: - Dynamic slider description
    private func sliderDescription(for minutes: Int) -> String {
        switch minutes {
        case 0..<150:
            return "Very low screen time — great for focus and better sleep!"
        case 150..<210:
            return "Healthy range — you're keeping things balanced."
        case 210..<270:
            return "Slightly high — consider taking short breaks to rest your eyes."
        case 270..<330:
            return "High screen time — try reducing usage for better wellbeing."
        case 330..<360:
            return "Very high — limiting time will help your focus and mood."
        default:
            return "Extremely high screen time — important to cut back for your health."
        }
    }




    private var weightWaterStep: some View {
        VStack(spacing: 28) {
            // Title
            VStack(spacing: 6) {
                Text("Daily water intake")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("Your recommended intake is based on your body weight.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 16)
            
            // Weight input card
            VStack(spacing: 16) {
                Text("Your weight")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Slider(value: Binding(
                        get: { Double(weightLbs) },
                        set: { weightLbs = Int($0) }
                    ), in: 50...400, step: 5).tint(.gray)
                    
                    Text("\(weightLbs) lbs")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 80)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(appGradient, lineWidth: 2)
            )
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Recommended water card
            VStack(spacing: 8) {
                Text("Recommended daily water")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(waterOunces) oz")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(appGradient, lineWidth: 2)
            )
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }

    // --- 7: Cold Showers
    private var coldShowerStep: some View {
        VStack(spacing: 28) {
            // Title + description
            VStack(spacing: 6) {
                Text("Cold showers")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text("We really recommend cold showers — they can boost mood, recovery, and discipline. But don’t worry if you can’t — just tap Continue to skip.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 16)
            
            // Cold shower days card
            VStack(spacing: 16) {
                Text("Which days will you take cold showers?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                DaysOfWeekPicker(selection: $coldShowerDays)
                
                if coldShowerDays.isEmpty {
                    Text("You can skip this step if you don’t want to include cold showers.")
                        .font(.footnote)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(appGradient, lineWidth: 2)
            )
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }

    
    // --- 8: Extra activities
    private var activitiesStep: some View {
        VStack(spacing: 16) {
            Text("Add other activities")
                .font(.title2).bold().foregroundColor(.white)
            
            Text("Pick up to 2 activities, then choose which days.")
                .foregroundColor(.gray).font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(activityOptions, id: \.self) { activity in
                    VStack(alignment: .leading, spacing: 12) {
                        // --- Select / Deselect activity
                        Button(action: {
                            if selectedActivities[activity] != nil {
                                selectedActivities.removeValue(forKey: activity)
                            } else if selectedActivities.count < 2 {
                                selectedActivities[activity] = ActivityConfig(frequency: 1, days: [])
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: activityIcon(for: activity))
                                    .frame(width: 22)
                                Text(activity).foregroundColor(.white)
                                Spacer()
                                Image(systemName: selectedActivities[activity] != nil ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundColor(selectedActivities[activity] != nil ? .green : .gray)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // --- Days picker if selected
                        if let config = selectedActivities[activity] {
                            DaysOfWeekPicker(selection: Binding(
                                get: { config.days },
                                set: { newValue in
                                    selectedActivities[activity]?.days = newValue
                                }
                            ))
                            .padding(.leading, 34)
                        }

                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
    
    // --- 9: Revisit addiction frequency
    private var revisitAddictionStep: some View {
        VStack(spacing: 28) {
            // Title
            VStack(spacing: 6) {
                if selectedAddictionNonEmpty {
                    Text("Let’s learn some more about your focus: \(selectedAddiction)")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                } else {
                    Text("Let’s revisit your main focus")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 16)
            
            addictionPickerButton
            
            if selectedAddictionNonEmpty {
                VStack(spacing: 20) {
                    // Question changes based on addiction
                    Text(questionForAddiction(selectedAddiction))
                        .font(.headline)
                             .foregroundColor(.white)
                             .multilineTextAlignment(.center)
                             .lineLimit(nil)
                             .fixedSize(horizontal: false, vertical: true)
                             .padding(.horizontal)
                    
                    Stepper(value: $addictionDaysPerWeek, in: 0...7) {
                        Text("\(addictionDaysPerWeek) \(addictionDaysPerWeek == 1 ? "day" : "days") per week")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(appGradient, lineWidth: 2)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            
            // Encouragement message (changes based on chosen days)
            if selectedAddictionNonEmpty {
                Text(footnoteForAddiction(selectedAddiction, days: addictionDaysPerWeek))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Helpers
    
    private var addictionPickerButton: some View {
        VStack(spacing: 12) {
            Text("Your main focus")
                .font(.subheadline.bold())
                .foregroundColor(.gray)
            
            Button(action: {
                showAddictionSheet.toggle()
            }) {
                HStack {
                    Text(selectedAddiction.isEmpty ? "Choose habit" : selectedAddiction)
                        .foregroundColor(selectedAddiction.isEmpty ? .gray : .white)
                        .bold()
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)
            }
            .sheet(isPresented: $showAddictionSheet) {
                VStack(spacing: 16) {
                    // Header
                    Text("Select your main focus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(addictionChoices, id: \.self) { choice in
                                Button(action: {
                                    selectedAddiction = choice
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: addictionIcon(for: choice))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 24)
                                        Text(choice)
                                            .foregroundColor(.white)
                                            .bold()
                                        Spacer()
                                        // Show checkmark if currently selected
                                        if selectedAddiction == choice {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        selectedAddiction == choice
                                            ? Color.green.opacity(0.2)
                                            : Color.white.opacity(0.05)
                                    )
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Done button
                    Button(action: {
                        showAddictionSheet = false
                    }) {
                        Text("Done")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
                .background(Color.black.ignoresSafeArea())
            }
        }
        .padding(.horizontal)
    }

    
    private func questionForAddiction(_ addiction: String) -> String {
        switch addiction.lowercased() {
        case "screentime": return "How many days a week do you spend too much time on screens?"
        case "porn": return "How many days a week do you watch it?"
        case "vaping": return "How many days a week do you vape?"
        case "smoking": return "How many days a week do you smoke?"
        case "alcohol": return "How many days a week do you drink?"
        case "gaming": return "How many days a week do you game excessively?"
        default: return "How many days a week do you usually do this?"
        }
    }

    private func footnoteForAddiction(_ addiction: String, days: Int) -> String {
        let activityWord: String
        switch addiction.lowercased() {
        case "screentime": activityWord = "screen time"
        case "porn": activityWord = "watching"
        case "vaping": activityWord = "vaping"
        case "smoking": activityWord = "smoking"
        case "alcohol": activityWord = "drinking"
        case "gaming": activityWord = "gaming"
        default: activityWord = "this habit"
        }
        
        if days == 0 {
            return "Amazing! You’re already ahead — we’ll help you stay consistent and free from \(activityWord)."
        } else if days <= 3 {
            return "That’s manageable. Over time, we’ll help you reduce those \(days) days of \(activityWord) even further."
        } else {
            return "Don’t worry — even with \(days) days of \(activityWord), we’ll guide you so that by the end of your journey, you can quit completely."
        }
    }


    
    // --- 10: Overview & final note
    private var overviewStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Plan Overview")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                // --- Main Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    summarySection(title: "Focus") {
                        summaryRow(icon: "target", title: "Major focus", value: selectedAddiction.isEmpty ? "None" : selectedAddiction)
                        summaryRow(icon: "flame", title: "Addiction severity", value: selectedAddiction.isEmpty ? "N/A" : "\(addictionDaysPerWeek) days/wk")
                    }
                    
                    summarySection(title: "Lifestyle") {
                        
                        summaryRow(icon: "sunrise", title: "Wake", value: "\(timeString(wakeWeekday)) / \(timeString(wakeWeekend))")
                        summaryRow(
                            icon: "moon.stars",
                            title: "Sleep",
                            value: {
                                let weekdayHours = Int(sleepHoursWeekday)
                                let weekdayMinutes = Int((sleepHoursWeekday - Double(weekdayHours)) * 60)
                                let weekendHours = Int(sleepHoursWeekend)
                                let weekendMinutes = Int((sleepHoursWeekend - Double(weekendHours)) * 60)

                                let weekdayString = "\(weekdayHours)h" + (weekdayMinutes > 0 ? " \(weekdayMinutes)m" : "")
                                let weekendString = "\(weekendHours)h" + (weekendMinutes > 0 ? " \(weekendMinutes)m" : "")
                                return "\(weekdayString) / \(weekendString)"
                            }()
                        )
                        summaryRow(
                            icon: "figure.strengthtraining.traditional",
                            title: "Workout",
                            value: {
                                guard !workoutDays.isEmpty else { return "None" }

                                let hours = Int(workoutHoursPerDay)
                                let minutes = Int((workoutHoursPerDay - Double(hours)) * 60)

                                let duration: String
                                if hours > 0 {
                                    duration = "\(hours)h" + (minutes > 0 ? " \(minutes)m" : "")
                                } else {
                                    duration = "\(minutes)m"
                                }

                                return "\(duration) • \(prettyDays(workoutDays))"
                            }()
                        )

                    }
                    
                    summarySection(title: "Health") {
                        
                        summaryRow(
                            icon: "iphone",
                            title: "Screen time",
                            value: {
                                guard screenLimitHours > 0 else { return "No" }

                                let hours = Int(screenLimitHours)
                                let minutes = Int((screenLimitHours - Double(hours)) * 60)

                                if hours > 0 {
                                    return "\(hours)h" + (minutes > 0 ? " \(minutes)m" : "") + "/day"
                                } else {
                                    return "\(minutes)m/day"
                                }
                            }()
                        )
                        summaryRow(icon: "scalemass", title: "Weight", value: "\(weightLbs) lbs")
                        summaryRow(icon: "drop", title: "Water", value: "\(waterOunces) oz")
                        summaryRow(icon: "snowflake", title: "Cold showers", value: (!coldShowerDays.isEmpty) ? "\(coldShowerDays.count)/week" : "No")
                    }
                    
                    summarySection(title: "Extra") {
                        summaryRow(icon: "star", title: "Activities", value: selectedActivities.isEmpty
                            ? "None"
                            : selectedActivities.map { "\($0.key): \($0.value.days.count)x" }.joined(separator: ", ")
                        )
                    }
                    
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // --- Final note section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Leave a note for your future self")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $finalNote)
                        .frame(height: 140)
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // --- Section wrapper
    @ViewBuilder
    private func summarySection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.gray)
            VStack(spacing: 8) {
                content()
            }
        }
    }

    // --- Row with icon
    @ViewBuilder
    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }

    
    // --- Completion view
    private var completionView: some View {
        VStack(spacing: 20) {
            Text("All set!").font(.largeTitle).bold().foregroundColor(.white)
            Text("Your plan is saved. You can tweak it anytime in settings.").foregroundColor(.gray)
            Button(action: { onFinish() }) {
                Text("Start Journey").font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity)
                    .background(appGradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        ZStack {
            SquareActionButton(
                label: currentStep == 0
                    ? "Let’s get started"
                    : (currentStep == maxStepIndex ? "Finish" : "Continue"),
                icon: currentStep == maxStepIndex ? "checkmark" : "chevron.right",
                disabled: isNextDisabled,
                loading: isSaving
            ) {
                handleContinue()
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            
            GeometryReader { proxy in
                Color.clear
                    .preference(key: NavHeightPreferenceKey.self, value: proxy.size.height)
            }
        }
        .frame(height: 84)
    }

    
    // MARK: - Next disabled validation
    private var isNextDisabled: Bool {
        switch currentStep {
        case 1:
            // Require a major focus selection
            return selectedAddiction.isEmpty
        case 4:
            return workoutDays.isEmpty
        case 5:
            // If they enabled limits, ensure a positive limit
            return screenLimitHours <= 0
        case 7:
            // If they enabled cold showers, ensure at least 1 day
            return takeColdShowers && coldShowerDays.isEmpty
        case 8:
            // If any selected activity has no days chosen, disable "Next"
            return selectedActivities.contains { _, config in
                config.days.isEmpty
            }
        default:
            return false
        }
    }

    
    private var selectedAddictionNonEmpty: Bool {
        !selectedAddiction.isEmpty
    }
    
    private func handleContinue() {
        if currentStep < maxStepIndex {
            currentStep += 1
        } else {
            saveFinalPlan()
        }
    }

    private func saveFinalPlan() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        let activitiesPayload: [String: [Int]] = selectedActivities.reduce(into: [String: [Int]]()) { partial, pair in
            let (activity, config) = pair
            partial[activity.lowercased()] = Array(config.days).sorted()
        }

        var payload: [String: Any] = [
            "majorFocus": selectedAddiction,
            "wakeWeekday": militaryTimeInt(from: wakeWeekday),
            "wakeWeekend": militaryTimeInt(from: wakeWeekend),
            "sleepHoursWeekday": sleepHoursWeekday,
            "sleepHoursWeekend": sleepHoursWeekend,
            "workoutHoursPerDay": workoutHoursPerDay,
            "workoutDays": Array(workoutDays),
            "screenLimitHours": screenLimitHours,
            "weightLbs": weightLbs,
            "waterOunces": waterOunces,
            "takeColdShowers": takeColdShowers,
            "coldShowerDays": Array(coldShowerDays),
            "selectedActivities": activitiesPayload,
            "addictionDaysPerWeek": addictionDaysPerWeek,
            "finalNote": finalNote,
            "isOnboarded": true
        ]

        let defaults: [String: Any] = [
            "rank": "Seeker",
            "xp": 0,
            "streak": 0,
            "animationsEnabled": true,
            "skills": [
                "Resilience": ["level": 1, "xp": 0],
                "Fuel": ["level": 1, "xp": 0],
                "Fitness": ["level": 1, "xp": 0],
                "Wisdom": ["level": 1, "xp": 0],
                "Discipline": ["level": 1, "xp": 0],
                "Network": ["level": 1, "xp": 0]
            ],
            "notifications": [
                "expiringTasks": true,
                "newTasks": true,
                "weeklyProgress": true
            ]
        ]

        payload.merge(defaults) { current, _ in current }

        isSaving = true
        docRef.setData(payload, merge: true) { error in
            isSaving = false
            if let error = error {
                print("Failed to save plan: \(error.localizedDescription)")
            } else {
                print("Plan + defaults saved, onboarding marked complete")
                onFinish()
            }
        }
    }




    // MARK: - Utilities
    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
    
    private func militaryTimeInt(from date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return hour * 100 + minute
    }
    
    private func prettyDays(_ days: Set<Int>) -> String {
        guard !days.isEmpty else { return "None" }
        // Keep mapping consistent with user's 1..7 (Mon..Sun)
        let map = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let names = days.sorted().map { idx -> String in
            let i = max(1, min(7, idx)) - 1
            return map[i]
        }
        return names.joined(separator: ", ")
    }
    
    private func addictionIcon(for name: String) -> String {
        switch name {
        case "Screentime": return "iphone.gen3.slash"
        case "Porn": return "eye.slash"
        case "Vaping": return "cloud"
        case "Smoking": return "flame"
        case "Alcohol": return "wineglass"
        case "Gaming": return "gamecontroller"
        default: return "circle"
        }
    }
    
    private func activityIcon(for name: String) -> String {
        switch name {
        case "Meditation": return "leaf"
        case "Reading": return "book"
        case "Pray": return "heart"
        case "Study": return "graduationcap"
        case "Walk": return "figure.walk"
        case "Run": return "figure.run"
        default: return "circle"
        }
    }
}

// MARK: - DaysOfWeekPicker
struct DaysOfWeekPicker: View {
    @Binding var selection: Set<Int>
    private let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    
    var body: some View {
        GeometryReader { geo in
            let totalSpacing: CGFloat = 10 * 6
            let buttonWidth = (geo.size.width - totalSpacing) / 7

            
            HStack(spacing: 10) {
                ForEach(1...7, id: \.self) { idx in
                    let isSelected = selection.contains(idx)
                    Button {
                        if isSelected {
                            selection.remove(idx)
                        } else {
                            selection.insert(idx)
                        }
                    } label: {
                        Text(days[idx-1])
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(isSelected ? .white : .gray)
                            .frame(width: buttonWidth, height: 46)
                            .background(
                                ZStack {
                                    if isSelected {
                                        appGradient
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        Color.white.opacity(0.05)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(appGradient, lineWidth: isSelected ? 0 : 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 46)
    }
}



// MARK: - OptionButton (with SF Symbol)
struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private func iconName() -> String {
        switch text {
        case "Screentime": return "iphone.gen3.slash"
        case "Porn": return "eye.slash"
        case "Vaping": return "cloud"
        case "Smoking": return "flame"
        case "Alcohol": return "wineglass"
        case "Gaming": return "gamecontroller"
        default: return "circle"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName())
                    .frame(width: 18)
                
                Text(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.white.opacity(0.02))
            .foregroundColor(isSelected ? .white : .gray)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(appGradient, lineWidth: isSelected ? 2 : 1)
                    .opacity(isSelected ? 1 : 0.35)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - SquareActionButton (replaces GradientButton)
struct SquareActionButton: View {
    var label: String? = nil
    let icon: String
    var disabled: Bool = false
    var loading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !disabled && !loading { action() }
        }) {
            if loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
                    .background(Color.black)
                    .cornerRadius(10)
            } else {
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appGradient)
                        .opacity(disabled ? 0.4 : 1)
                    
                    // Border
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    
                    // Content
                    HStack(spacing: 10) {
                        if let label = label {
                            Text(label)
                        }
                        Image(systemName: icon)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .opacity(disabled ? 0.55 : 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled || loading)
    }
}

