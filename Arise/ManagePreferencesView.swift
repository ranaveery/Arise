import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct ManagePreferencesView: View {
    // MARK: - Stored Preferences
    @State private var majorFocus = ""
    @State private var wakeWeekday = 420
    @State private var wakeWeekend = 480
    @State private var sleepHoursWeekday: Double = 8
    @State private var sleepHoursWeekend: Double = 8
    @State private var workoutMinutesPerDay = 60
    @State private var workoutDaysPerWeek = 3
    @State private var workoutDays: Set<Int> = []
    @State private var screenLimitMinutes = 120
    @State private var weightLbs = 160
    @State private var waterOunces: Double = 120
    @State private var takeColdShowers = false
    @State private var coldShowersPerWeek = 0
    @State private var selectedActivities: [String: Int] = [:]
    @State private var addictionSeverity = 5
    @State private var finalNote = ""
    @State private var showWakeTimePicker = false
    @State private var showSleepHoursPicker = false
    @State private var showWorkoutMinutesPicker = false
    @State private var showScreenLimitPicker = false
    @State private var showColdShowerPicker = false
    // MARK: - UI State
    @State private var isSaving = false
    @State private var savedSuccessfully = false
    @State private var showFocusPicker = false
    @State private var showWorkoutDayPicker = false
    @State private var showActivityPicker = false
    
    // MARK: - Constants
    private let focusOptions = ["Smoking", "Gaming", "Screentime", "Alcohol", "Vaping", "Porn", "Other"]
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let activityOptions = ["Meditation", "Reading", "Journaling", "Exercise", "Breathing"]
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 84/255, green: 0/255, blue: 232/255),
                                    Color(red: 236/255, green: 71/255, blue: 1/255)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Preferences")
                    .font(.largeTitle.bold())
                    .foregroundStyle(gradient)
                    .padding(.top, 20)
                
                VStack(spacing: 1) {
                    
                    // Major Focus
                    preferenceRow(title: "Major Focus", value: majorFocus.isEmpty ? "Not set" : majorFocus, systemImage: "flame.fill", isEditable: true, isExpanded: $showFocusPicker) {
                        VStack(spacing: 5) {
                            ForEach(focusOptions, id: \.self) { option in
                                dropdownOption(option, isSelected: majorFocus == option) { changePreference { majorFocus = option } }
                            }
                        }.padding(.vertical, 5)
                    }
                    
                    // Workout Days
                    preferenceRow(title: "Workout Days", value: workoutDays.isEmpty ? "Not set" : workoutDays.map { weekDays[$0-1] }.joined(separator: ", "), systemImage: "figure.strengthtraining.traditional", isEditable: true, isExpanded: $showWorkoutDayPicker) {
                        VStack(spacing: 5) {
                            ForEach(1...7, id: \.self) { day in
                                MultiSelectOptionButton(text: weekDays[day-1], isSelected: workoutDays.contains(day)) {
                                    changePreference { toggleDaySelection(day) }
                                }
                            }
                        }.padding(.vertical, 5)
                    }
                    
                    // Activities
                    preferenceRow(title: "Activities", value: selectedActivities.isEmpty ? "None" : selectedActivities.map { "\($0.key): \($0.value)x" }.joined(separator: ", "), systemImage: "star.fill", isEditable: true, isExpanded: $showActivityPicker) {
                        VStack(spacing: 5) {
                            ForEach(activityOptions, id: \.self) { option in
                                Stepper("\(option): \(selectedActivities[option] ?? 0)x", value: Binding(
                                    get: { selectedActivities[option] ?? 0 },
                                    set: { newValue in changePreference { selectedActivities[option] = newValue } }
                                ), in: 0...7)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }.padding(.vertical, 5)
                    }
                    
                    // Wake Times
                    preferenceRow(
                        title: "Wake Times",
                        value: "Weekday: \(wakeWeekday / 100):\(String(format: "%02d", wakeWeekday % 100)), Weekend: \(wakeWeekend / 100):\(String(format: "%02d", wakeWeekend % 100))",
                        systemImage: "alarm.fill",
                        isEditable: true,
                        isExpanded: $showWakeTimePicker
                    ) {
                        VStack {
                            Stepper("Weekday: \(timeString(from: wakeWeekday))", onIncrement: {
                                stepTime(&wakeWeekday, step: 15)
                            }, onDecrement: {
                                stepTime(&wakeWeekday, step: -15)
                            })
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)

                            Stepper("Weekend: \(timeString(from: wakeWeekend))", onIncrement: {
                                stepTime(&wakeWeekend, step: 15)
                            }, onDecrement: {
                                stepTime(&wakeWeekend, step: -15)
                            })
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }.padding(.vertical, 5)
                    }

                    // Sleep Hours
                    preferenceRow(
                        title: "Sleep Hours",
                        value: "Weekday: \(Int(sleepHoursWeekday))h, Weekend: \(Int(sleepHoursWeekend))h",
                        systemImage: "bed.double.fill",
                        isEditable: true,
                        isExpanded: $showSleepHoursPicker
                    ) {
                        VStack {
                            Stepper("Weekday: \(Int(sleepHoursWeekday))h", value: $sleepHoursWeekday, in: 4...12, step: 1)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            Stepper("Weekend: \(Int(sleepHoursWeekend))h", value: $sleepHoursWeekend, in: 4...12, step: 1)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                        }.padding(.vertical, 5)
                    }

                    // Workout Minutes per Day
                    preferenceRow(
                        title: "Workout Duration",
                        value: "\(workoutMinutesPerDay) min",
                        systemImage: "timer",
                        isEditable: true,
                        isExpanded: $showWorkoutMinutesPicker
                    ) {
                        Stepper("Minutes: \(workoutMinutesPerDay)", value: $workoutMinutesPerDay, in: 15...180, step: 15)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }

                    // Screen Limit
                    preferenceRow(
                        title: "Screen Limit",
                        value: "\(screenLimitMinutes / 60) hr",
                        systemImage: "iphone",
                        isEditable: true,
                        isExpanded: $showScreenLimitPicker
                    ) {
                        Stepper("Hours: \(screenLimitMinutes / 60)", value: Binding(
                            get: { screenLimitMinutes / 60 },
                            set: { newValue in changePreference { screenLimitMinutes = newValue * 60 } }
                        ), in: 1...12)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }

                    // Cold Showers
                    preferenceRow(
                        title: "Cold Showers",
                        value: takeColdShowers ? "\(coldShowersPerWeek)x / week" : "Off",
                        systemImage: "snowflake",
                        isEditable: true,
                        isExpanded: $showColdShowerPicker
                    ) {
                        VStack(spacing: 10) {
                            Toggle("Enable Cold Showers", isOn: Binding(
                                get: { takeColdShowers },
                                set: { newValue in changePreference { takeColdShowers = newValue } }
                            ))
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .tint(Color.blue)
                            
                            if takeColdShowers {
                                Stepper("Times per week: \(coldShowersPerWeek)", value: $coldShowersPerWeek, in: 0...7)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                
                                HStack {
                                    ForEach(1...7, id: \.self) { day in
                                        MultiSelectOptionButton(text: weekDays[day-1], isSelected: workoutDays.contains(day)) {
                                            changePreference { toggleDaySelection(day) }
                                        }
                                    }
                                }
                            }
                        }.padding(.vertical, 5)
                    }
                    
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Save Button
                Button(action: savePreferences) {
                    ZStack {
                        if isSaving {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack {
                                if savedSuccessfully {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                }
                                Text(savedSuccessfully ? "Saved" : "Save Changes")
                                    .fontWeight(.bold).foregroundColor(.white)
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(gradient)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .disabled(isSaving)
                
                Text("Options unavailable here cannot be changed once set.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: loadPreferences)
    }
    
    private func timeString(from value: Int) -> String {
        let hour = value / 60
        let minute = value % 60
        return String(format: "%d:%02d", hour, minute)
    }

    private func stepTime(_ value: inout Int, step: Int) {
        value = (value + step).clamped(to: 0...24*60)
    }
    
    // MARK: - UI Helpers
    private func toggleDaySelection(_ day: Int) {
        if workoutDays.contains(day) {
            workoutDays.remove(day)
        } else {
            workoutDays.insert(day)
        }
    }
    
    private func changePreference(_ action: @escaping () -> Void) {
        action()
        savedSuccessfully = false
    }
    
    @ViewBuilder
    private func dropdownOption(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(text).foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 84/255, green: 0/255, blue: 232/255))
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    struct MultiSelectOptionButton: View {
        let text: String
        let isSelected: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack {
                    Text(text)
                        .fontWeight(.medium)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 84/255, green: 0/255, blue: 232/255))
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(
                            gradient: Gradient(colors: isSelected
                                ? [Color(red: 84/255, green: 0/255, blue: 232/255),
                                   Color(red: 236/255, green: 71/255, blue: 1/255)]
                                : [.clear, .clear]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: isSelected ? 2 : 1)
                )
                .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private func preferenceRow<Content: View>(
        title: String,
        value: String,
        systemImage: String,
        isEditable: Bool,
        isExpanded: Binding<Bool>? = nil,
        @ViewBuilder dropdownContent: () -> Content = { EmptyView() }
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isExpanded?.wrappedValue.toggle() } }) {
                HStack {
                    Image(systemName: systemImage)
                        .foregroundStyle(gradient)
                        .frame(width: 25)
                    
                    Text(title)
                        .foregroundColor(.white)

                    Spacer()
                    
                    if title == "Gender" {
                        Text(value)
                            .foregroundColor(.white)
                    }
                    
                    if isEditable {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded?.wrappedValue == true ? 90 : 0))
                            .foregroundColor(.gray)
                            .animation(.easeInOut(duration: 0.25), value: isExpanded?.wrappedValue)
                    }
                }
                .padding()
            }
            
            if isExpanded?.wrappedValue == true {
                dropdownContent()
                    .animation(.easeInOut(duration: 0.3), value: isExpanded?.wrappedValue)
                    .transition(.opacity)
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            majorFocus = data["majorFocus"] as? String ?? ""
            wakeWeekday = data["wakeWeekday"] as? Int ?? 700
            wakeWeekend = data["wakeWeekend"] as? Int ?? 800
            sleepHoursWeekday = data["sleepHoursWeekday"] as? Double ?? 8
            sleepHoursWeekend = data["sleepHoursWeekend"] as? Double ?? 8
            workoutMinutesPerDay = data["workoutMinutesPerDay"] as? Int ?? 60
            workoutDaysPerWeek = data["workoutDaysPerWeek"] as? Int ?? 3
            if let days = data["workoutDays"] as? [Int] { workoutDays = Set(days) }
            screenLimitMinutes = data["screenLimitMinutes"] as? Int ?? 120
            weightLbs = data["weightLbs"] as? Int ?? 160
            waterOunces = data["waterOunces"] as? Double ?? Double(weightLbs) * 2/3
            takeColdShowers = data["takeColdShowers"] as? Bool ?? false
            coldShowersPerWeek = data["coldShowersPerWeek"] as? Int ?? 0
            selectedActivities = data["selectedActivities"] as? [String: Int] ?? [:]
            addictionSeverity = data["addictionSeverity"] as? Int ?? 5
            finalNote = data["finalNote"] as? String ?? ""
        }
    }
    
    private func savePreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        Firestore.firestore().collection("users").document(uid).setData([
            "majorFocus": majorFocus,
            "wakeWeekday": wakeWeekday,
            "wakeWeekend": wakeWeekend,
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
            "finalNote": finalNote
        ], merge: true) { _ in
            isSaving = false
            withAnimation { savedSuccessfully = true }
        }
    }
}
