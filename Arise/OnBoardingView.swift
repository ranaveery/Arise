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

// PreferenceKey to measure bottom nav height (keeps UI above nav)
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
    @State private var majorFocus: String = "" // placeholder (not used directly in final plan)
    
    // Wake time (weekday/weekend)
    @State private var wakeWeekday: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeWeekend: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Sleep duration (hours)
    @State private var sleepHoursWeekday: Double = 7.5
    @State private var sleepHoursWeekend: Double = 8.5
    
    // Workout
    @State private var workoutMinutesPerDay: Int = 30
    @State private var workoutDaysPerWeek: Int = 3
    @State private var workoutDays: Set<Int> = [1,3,5] // Monday=1 ... Sunday=7
    
    // Screen time
    @State private var limitScreenTime: Bool = false
    @State private var screenLimitMinutes: Int = 120
    
    // Weight -> water
    @State private var weightLbs: Int = 160
    private var waterOunces: Double { Double(weightLbs) * (2.0/3.0) }
    
    // Cold showers
    @State private var takeColdShowers: Bool = false
    @State private var coldShowersPerWeek: Int = 2
    
    // Extra activities
    let activityOptions = ["Meditation","Cold Water Plunge","Reading","Pray","Study","Walk","Run","Sauna"]
    @State private var selectedActivities: [String: Int] = [:] // activity -> times per week
    
    // Revisit addictions severity
    @State private var addictionChoices: [String] = ["Screentime","Porn","Vaping","Smoking","Alcohol","Gaming"]
    @State private var selectedAddiction: String = ""
    @State private var addictionSeverity: Int = 3 // 1-10
    
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
            Text("How long do you want to sleep?")
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

            Spacer()

            VStack(spacing: 20) {
                // --- Weekdays
                VStack(spacing: 12) {
                    HStack {
                        Text("Weekdays")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        let hours = Int(sleepHoursWeekday)
                        let minutes = Int((sleepHoursWeekday - Double(hours)) * 60)

                        Text("\(hours)h\(minutes > 0 ? " \(minutes)m" : "")")
                            .foregroundColor(.white)
                    }
                    VStack {
                        Slider(value: $sleepHoursWeekday, in: 6...12, step: 0.25)
                    }
                    .tint(.gray)

                    if let bedtime = calculateBedtime(wakeTime: wakeWeekday, sleepHours: sleepHoursWeekday) {
                        Text("You should go to bed around **\(bedtime)**")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)

                // --- Weekends
                VStack(spacing: 12) {
                    HStack {
                        Text("Weekends")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        let hours_end = Int(sleepHoursWeekend)
                        let minutes_end = Int((sleepHoursWeekend - Double(hours_end)) * 60)

                        Text("\(hours_end)h\(minutes_end > 0 ? " \(minutes_end)m" : "")")
                            .foregroundColor(.white)
                    }

                    VStack {
                        Slider(value: $sleepHoursWeekend, in: 6...12, step: 0.25)
                    }
                    .tint(.gray)

                    if let bedtime = calculateBedtime(wakeTime: wakeWeekend, sleepHours: sleepHoursWeekend) {
                        Text("You should go to bed around **\(bedtime)**")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
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
        guard let bedtime = calendar.date(byAdding: .hour, value: -Int(sleepHours), to: wakeTime) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedtime)
    }

    
    // --- 4: Workout preferences
    private var workoutStep: some View {
        VStack(spacing: 24) {
            // Title
            Text("Workout preferences")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 8)

            // Subtitle
            Text("Set how much you want to work out each week.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 20) {
                // Minutes per day
                VStack(spacing: 12) {
                    HStack {
                        Text("Minutes per day")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(workoutMinutesPerDay) min")
                            .foregroundColor(.white)
                    }

                    Stepper("", value: $workoutMinutesPerDay, in: 15...180, step: 15)
                        .labelsHidden()
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)

                // Days per week
                VStack(spacing: 12) {
                    HStack {
                        Text("Days per week")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(workoutDaysPerWeek) days")
                            .foregroundColor(.white)
                    }

                    Stepper("", value: $workoutDaysPerWeek, in: 0...7)
                        .labelsHidden()
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)

                // Preferred days
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pick days of the week you prefer")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DaysOfWeekPicker(selection: $workoutDays)
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(16)
            }
            .padding(.horizontal)

            Spacer()

            // Tip
            Text("Choose a frequency that you can be consistent with — consistency > intensity.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }

    
    // --- 5: Screen time
    private var screenTimeStep: some View {
        VStack(spacing: 24) {
            // Title
            Text("Set your daily screen time limit")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // Screen time input (slider + value)
            VStack(spacing: 12) {
                Text("Daily limit")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Slider(value: Binding(
                        get: { Double(screenLimitMinutes) },
                        set: { screenLimitMinutes = Int($0) }
                    ), in: 15...360, step: 15)
                    
                    Text("\(screenLimitMinutes) min")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 80)
                }
            }
            .padding(.horizontal)
            
            Spacer() // pushes the result card down
            
            // Result card with gradient ring
            VStack(spacing: 8) {
                Text("Your daily screen goal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(screenLimitMinutes) minutes")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(appGradient, lineWidth: 2)
            )
            .cornerRadius(18)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }


    private var weightWaterStep: some View {
        ZStack {
            // Fullscreen background image
            Image("onboarding_waterimage")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity) // take full space
                .ignoresSafeArea() // extend behind safe areas
            
            // Dark overlay to dim the background
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 24) {
                Text("Let’s calculate your daily water intake")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    Text("Your weight")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack(spacing: 12) {
                        Slider(value: Binding(
                            get: { Double(weightLbs) },
                            set: { weightLbs = Int($0) }
                        ), in: 50...400, step: 5)

                        Text("\(weightLbs) lbs")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 8) {
                    Text("Recommended Daily Water")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(String(format: "%.0f", waterOunces)) oz")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(appGradient, lineWidth: 2)
                )
                .cornerRadius(18)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }


    // --- 7: Cold showers
    private var coldShowerStep: some View {
        VStack(spacing: 16) {
            Text("Cold showers").font(.title2).bold().foregroundColor(.white)
            Toggle(isOn: $takeColdShowers) {
                Text(takeColdShowers ? "Yes — add to plan" : "No, thanks")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            if takeColdShowers {
                Stepper("Times per week: \(coldShowersPerWeek)", value: $coldShowersPerWeek, in: 1...7)
            }
        }
    }
    
    // --- 8: Extra activities
    private var activitiesStep: some View {
        VStack(spacing: 16) {
            Text("Add other activities").font(.title2).bold().foregroundColor(.white)
            Text("Select activities you want and set weekly frequency.")
                .foregroundColor(.gray).font(.footnote)
            VStack(spacing: 10) {
                ForEach(activityOptions, id: \.self) { activity in
                    HStack {
                        Button(action: {
                            if selectedActivities[activity] != nil {
                                selectedActivities.removeValue(forKey: activity)
                            } else {
                                selectedActivities[activity] = 1
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
                        
                        if selectedActivities[activity] != nil {
                            Stepper("\(selectedActivities[activity] ?? 1)", value: Binding(
                                get: { selectedActivities[activity] ?? 1 },
                                set: { selectedActivities[activity] = $0 }
                            ), in: 1...14)
                            .labelsHidden()
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
    
    // --- 9: Revisit addiction severity
    private var revisitAddictionStep: some View {
        VStack(spacing: 16) {
            Text("Let’s revisit your main focus")
                .font(.title2).bold().foregroundColor(.white)
            if selectedAddictionNonEmpty {
                HStack {
                    Image(systemName: addictionIcon(for: selectedAddiction))
                    Text("You chose: \(selectedAddiction)")
                        .foregroundColor(.white.opacity(0.9))
                }
            } else {
                Text("You didn't pick a specific item earlier — choose one now or skip.")
                    .foregroundColor(.gray).font(.footnote).multilineTextAlignment(.center)
            }
            Picker("Which habit?", selection: $selectedAddiction) {
                Text("None").tag("")
                ForEach(addictionChoices, id: \.self) { s in
                    Label(s, systemImage: addictionIcon(for: s)).tag(s)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            VStack(alignment: .leading) {
                Text("How bad is it on a scale 1–10?").foregroundColor(.white)
                Slider(value: Binding(
                    get: { Double(addictionSeverity) },
                    set: { addictionSeverity = Int($0) }
                ), in: 1...10, step: 1)
                Text("Severity: \(addictionSeverity) / 10").foregroundColor(.gray)
            }
            
            Text("It’s okay — change is gradual. We’ll help you slowly decrease it over time. You can edit this later.")
                .font(.footnote).foregroundColor(.white.opacity(0.75)).multilineTextAlignment(.center)
                .padding(.top, 6)
        }
    }
    
    // --- 10: Overview & final note
    private var overviewStep: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Your plan overview").font(.title2).bold().foregroundColor(.white)
                
                Group {
                    summaryRow(title: "Major focus", value: selectedAddiction.isEmpty ? "None" : selectedAddiction)
                    summaryRow(title: "Wake (wk/wknd)", value: "\(timeString(wakeWeekday)) / \(timeString(wakeWeekend))")
                    summaryRow(title: "Sleep (hrs wk/wknd)", value: String(format: "%.1f / %.1f", sleepHoursWeekday, sleepHoursWeekend))
                    summaryRow(title: "Workout", value: "\(workoutMinutesPerDay) min • \(workoutDaysPerWeek) days • days: \(prettyDays(workoutDays))")
                    summaryRow(title: "Screen time limit", value: limitScreenTime ? "\(screenLimitMinutes) min/day" : "No limit")
                    summaryRow(title: "Weight / Water", value: "\(weightLbs) lbs / \(String(format: "%.0f oz", waterOunces))")
                    summaryRow(title: "Cold showers", value: takeColdShowers ? "\(coldShowersPerWeek)/week" : "No")
                    summaryRow(title: "Activities", value: selectedActivities.isEmpty ? "None" : selectedActivities.map { "\($0.key): \($0.value)/wk" }.joined(separator: ", "))
                    summaryRow(title: "Addiction severity", value: selectedAddiction.isEmpty ? "N/A" : "\(addictionSeverity)/10")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Leave a note for your future self:").foregroundColor(.white).bold()
                    TextEditor(text: $finalNote)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
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
        .frame(height: 84) // keeps nav bar at a predictable size
    }

    
    // MARK: - Next disabled validation
    private var isNextDisabled: Bool {
        switch currentStep {
        case 1:
            // Require a major focus selection
            return selectedAddiction.isEmpty
        case 4:
            // If they want to work out >0 days/wk, ensure they actually picked days
            return workoutDaysPerWeek > 0 && workoutDays.isEmpty
        case 5:
            // If they enabled limits, ensure a positive limit
            return limitScreenTime && screenLimitMinutes <= 0
        case 7:
            // If they enabled cold showers, ensure times > 0
            return takeColdShowers && coldShowersPerWeek <= 0
        default:
            return false
        }
    }
    
//    private var selectedAddictionNonEmpty: Bool { !majorFocus.isEmpty || !selectedAddiction.isEmpty }
    private var selectedAddictionNonEmpty: Bool {
        !selectedAddiction.isEmpty
    }

    
    // MARK: - Save / navigation logic (kept same as yours, slightly formatted)
    private func saveStep(_ stepName: String, payload: [String: Any]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        let db = Firestore.firestore()
        let ref = db.collection("onboardings").document(uid)
        var data = payload
        data["lastStep"] = stepName
        data["updatedAt"] = FieldValue.serverTimestamp()
        ref.setData(data, merge: true) { err in
            isSaving = false
            if let err = err {
                print("Failed saving step \(stepName): \(err)")
            }
        }
    }
    
    private func completeOnboarding() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "isOnboarded": true
        ], merge: true) { error in
            isSaving = false
            if let error = error {
                print("Error marking onboarded: \(error)")
                return
            }
            onFinish()
        }
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

        let payload: [String: Any] = [
            "isOnboarded": true,
            "majorFocus": selectedAddiction,
            "wakeWeekday": militaryTimeInt(from: wakeWeekday),
            "wakeWeekend": militaryTimeInt(from: wakeWeekend),
            "sleepHoursWeekday": sleepHoursWeekday,
            "sleepHoursWeekend": sleepHoursWeekend,
            "workoutMinutesPerDay": workoutMinutesPerDay,
            "workoutDaysPerWeek": workoutDaysPerWeek,
            "workoutDays": Array(workoutDays),
            "screenLimitMinutes": screenLimitMinutes,
            "weightLbs": weightLbs,
            "waterOunces": waterOunces,
            "takeColdShowers": takeColdShowers,
            "coldShowersPerWeek": coldShowersPerWeek,
            "selectedActivities": selectedActivities,
            "addictionSeverity": addictionSeverity,
            "finalNote": finalNote,
        ]

        isSaving = true
        docRef.setData(payload, merge: true) { error in
            isSaving = false
            if let error = error {
                print("Failed to save plan: \(error.localizedDescription)")
            } else {
                print("Plan saved")
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
    
    @ViewBuilder
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.gray)
            Spacer()
            Text(value).foregroundColor(.white)
        }
        .padding(.vertical, 6)
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
        case "Cold Water Plunge": return "drop.fill"
        case "Reading": return "book"
        case "Pray": return "heart"
        case "Study": return "graduationcap"
        case "Walk": return "figure.walk"
        case "Run": return "figure.run"
        case "Sauna": return "flame"
        default: return "circle"
        }
    }
}

// MARK: - DaysOfWeekPicker
struct DaysOfWeekPicker: View {
    @Binding var selection: Set<Int>
    // We'll show Mon..Sun as 1..7 for clarity
    let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(1...7), id: \.self) { idx in
                let isSelected = selection.contains(idx)
                Button(action: {
                    if isSelected {
                        selection.remove(idx)
                    } else {
                        selection.insert(idx)
                    }
                }) {
                    Text(days[idx-1])
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .gray)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(appGradient)
                                .opacity(isSelected ? 1 : 0)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
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
            HStack(spacing: 6) { // tighter spacing
                Image(systemName: iconName())
                    .frame(width: 18)
                
                Text(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1) // keeps text from shrinking too much
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 14) // more vertical padding
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 56) // bigger tap area
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
                .frame(maxWidth: .infinity, minHeight: 56) // takes entire width
                .opacity(disabled ? 0.55 : 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled || loading)
    }
}

