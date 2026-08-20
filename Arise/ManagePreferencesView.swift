import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Helper to clamp numbers
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct ManagePreferencesView: View {
    // MARK: - State
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var majorFocus = ""
    @State private var wakeWeekday = Date()
    @State private var wakeWeekend = Date()
    @State private var sleepHoursWeekday = 8.0
    @State private var sleepHoursWeekend = 8.0
    @State private var workoutHoursPerDay = 1.0
    @State private var screenLimitHours = 2.0
    @State private var weightLbs = 160
    @State private var waterOunces = 106
    @State private var coldShowerDays: Set<Int> = []
    @State private var selectedActivities: [String: [Int]] = [:]
    @State private var addictionDaysPerWeek: Int = 0
    @State private var workoutDays: Set<Int> = []

    @State private var expandedSection: String? = nil
    @State private var isSaving = false
    @State private var savedSuccessfully = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Constants
    private let focusOptions = ["Smoking", "Gaming", "Screentime", "Alcohol", "Vaping", "Porn"]
    private let activityOptions = ["Meditation", "Reading", "Pray", "Study", "Walk", "Run"]
    private let weekLetters = ["M", "T", "W", "T", "F", "S", "S"]
    private let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    private let gradient = LinearGradient.brand

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Manage Preferences")
                    .font(.title.bold())
                    .foregroundStyle(gradient)
                    .padding(.top)

                focusSection
                wakeWeekdaySection
                wakeWeekendSection
                sleepWeekdaySection
                sleepWeekendSection
                workoutSection
                screenLimitSection
                weightSection
                coldShowerSection
                activitiesSection

                saveButton
            }
            .padding(.horizontal)
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: loadPreferences)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Expandable Sections
    private var focusSection: some View {
        expandableSection(title: "Main Focus", systemImage: "flame.fill") {
            VStack(spacing: 8) {
                ForEach(focusOptions, id: \.self) { option in
                    Button {
                        majorFocus = (majorFocus == option ? "" : option)
                        savedSuccessfully = false
                    } label: {
                        HStack {
                            Text(option).foregroundColor(.white)
                            Spacer()
                            if majorFocus == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .accessibilityLabel(option)
                    .accessibilityAddTraits(majorFocus == option ? .isSelected : [])
                }
            }
        }
    }

    private var wakeWeekdaySection: some View {
        expandableSection(title: "Wake Time (Weekday)", systemImage: "sunrise.fill") {
            timePicker(for: $wakeWeekday)
        }
    }

    private var wakeWeekendSection: some View {
        expandableSection(title: "Wake Time (Weekend)", systemImage: "sunrise.circle.fill") {
            timePicker(for: $wakeWeekend)
        }
    }

    private var sleepWeekdaySection: some View {
        expandableSection(title: "Sleep Hours (Weekday)", systemImage: "moon.zzz.fill") {
            durationPicker(for: $sleepHoursWeekday)
        }
    }

    private var sleepWeekendSection: some View {
        expandableSection(title: "Sleep Hours (Weekend)", systemImage: "moon.stars.fill") {
            durationPicker(for: $sleepHoursWeekend)
        }
    }

    private var workoutSection: some View {
        expandableSection(title: "Workout Duration", systemImage: "figure.run.circle.fill") {
            durationPicker(for: $workoutHoursPerDay, range: 0.5...3)
        }
    }

    private var screenLimitSection: some View {
        expandableSection(title: "Screen Limit", systemImage: "iphone.gen3.circle.fill") {
            durationPicker(for: $screenLimitHours, range: 0.5...8)
        }
    }

    private var weightSection: some View {
        expandableSection(title: "Weight & Water Goal", systemImage: "scalemass.fill") {
            VStack(spacing: 10) {
                Slider(value: Binding(
                    get: { Double(weightLbs) },
                    set: {
                        let rounded = Int(($0 / 5.0).rounded() * 5)
                        weightLbs = rounded.clamped(to: 50...400)
                        updateWater()
                        savedSuccessfully = false
                    }
                ), in: 50...400, step: 5)
                .tint(.gray)
                .accessibilityLabel("Weight")
                .accessibilityValue("\(weightLbs) pounds")
                HStack {
                    Text("\(weightLbs) lbs").foregroundColor(.white)
                    Spacer()
                    Text("\(waterOunces) oz water").foregroundColor(.gray)
                }
                .font(.subheadline)
            }
        }
    }

    private var coldShowerSection: some View {
        expandableSection(title: "Cold Shower Days", systemImage: "drop.fill") {
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    Button {
                        if coldShowerDays.contains(day) {
                            coldShowerDays.remove(day)
                        } else {
                            coldShowerDays.insert(day)
                        }
                        savedSuccessfully = false
                    } label: {
                        Text(weekLetters[day - 1])
                            .font(.subheadline.bold())
                            .foregroundColor(coldShowerDays.contains(day) ? .white : .gray)
                            .padding(.vertical, 8)
                            .frame(minWidth: 35)
                            .background(
                                coldShowerDays.contains(day)
                                ? AnyView(RoundedRectangle(cornerRadius: 8).fill(gradient))
                                : AnyView(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.10)))
                            )
                    }
                    .accessibilityLabel(dayNames[day - 1])
                }
            }
        }
    }

    private var activitiesSection: some View {
        expandableSection(title: "Activities (Max 2)", systemImage: "figure.mind.and.body") {
            VStack(spacing: 12) {
                ForEach(activityOptions, id: \.self) { option in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            if selectedActivities.keys.contains(option) {
                                selectedActivities.removeValue(forKey: option)
                            } else if selectedActivities.count < 2 {
                                selectedActivities[option] = []
                            }
                            savedSuccessfully = false
                        } label: {
                            HStack {
                                Text(option).foregroundColor(.white)
                                Spacer()
                                Image(systemName: selectedActivities.keys.contains(option)
                                      ? "checkmark.circle.fill"
                                      : "chevron.down")
                                .foregroundColor(selectedActivities.keys.contains(option) ? .green : .gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .accessibilityLabel(option)
                        .accessibilityAddTraits(selectedActivities.keys.contains(option) ? .isSelected : [])

                        if let days = selectedActivities[option] {
                            HStack(spacing: 8) {
                                ForEach(1...7, id: \.self) { day in
                                    Button {
                                        var updated = days
                                        if updated.contains(day) {
                                            updated.removeAll { $0 == day }
                                        } else {
                                            updated.append(day)
                                        }
                                        selectedActivities[option] = updated.sorted()
                                        savedSuccessfully = false
                                    } label: {
                                        Text(weekLetters[day - 1])
                                            .font(.subheadline.bold())
                                            .foregroundColor(days.contains(day) ? .white : .gray)
                                            .padding(.vertical, 8)
                                            .frame(minWidth: 35)
                                            .background(
                                                days.contains(day)
                                                ? AnyView(RoundedRectangle(cornerRadius: 8).fill(gradient))
                                                : AnyView(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.10)))
                                            )
                                    }
                                    .accessibilityLabel(dayNames[day - 1])
                                }
                            }
                            .animation(animationsEnabled ? .easeInOut : nil, value: selectedActivities)
                        }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: savePreferences) {
            ZStack {
                if isSaving {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, minHeight: 50)
                } else {
                    Text(savedSuccessfully ? "Saved" : "Save Changes")
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(gradient)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
        }
        .accessibilityLabel(savedSuccessfully ? "Saved" : "Save Changes")
        .padding(.bottom, 20)
    }

    // MARK: - Picker Builders
    private func timePicker(for date: Binding<Date>) -> some View {
        Picker("", selection: Binding(
            get: {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date.wrappedValue)
                return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            },
            set: { totalMinutes in
                let hours = totalMinutes / 60
                let minutes = totalMinutes % 60
                date.wrappedValue = Calendar.current.date(from: DateComponents(hour: hours, minute: minutes)) ?? Date()
            }
        )) {
            ForEach(Array(stride(from: 0, to: 1440, by: 15)), id: \.self) { m in
                Text(timeString(from: m)).tag(m)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 100)
    }

    private func durationPicker(for hours: Binding<Double>, range: ClosedRange<Double> = 4...12) -> some View {
        Picker("", selection: Binding(
            get: { Int(hours.wrappedValue * 60) },
            set: { hours.wrappedValue = Double($0) / 60.0 }
        )) {
            ForEach(Array(stride(from: Int(range.lowerBound * 60), through: Int(range.upperBound * 60), by: 15)), id: \.self) { minutes in
                let h = minutes / 60
                let m = minutes % 60
                Text(m == 0 ? "\(h) hr" : "\(h) hr \(m) min").tag(minutes)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 100)
    }

    // MARK: - Shared Expandable Section View
    @ViewBuilder
    private func expandableSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if animationsEnabled {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        expandedSection = (expandedSection == title ? nil : title)
                    }
                } else {
                    expandedSection = (expandedSection == title ? nil : title)
                }
            } label: {
                HStack {
                    Image(systemName: systemImage).foregroundStyle(gradient)
                    Text(title).foregroundColor(.white)
                    Spacer()
                    Image(systemName: expandedSection == title ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            }
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHint(expandedSection == title ? "Collapse section" : "Expand section")

            if expandedSection == title {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Helpers
    private func timeString(from minutes: Int) -> String {
        let hour = (minutes / 60) % 24
        let minute = minutes % 60
        let isPM = hour >= 12
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, isPM ? "PM" : "AM")
    }

    private func updateWater() {
        waterOunces = Int((Double(weightLbs) * 2 / 3).rounded())
    }

    // MARK: - Firestore
    private func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }

            DispatchQueue.main.async {
                self.majorFocus = data["majorFocus"] as? String ?? ""
                if let weekdayInt = data["wakeWeekday"] as? Int { self.wakeWeekday = self.dateFromMilitary(weekdayInt) }
                if let weekendInt = data["wakeWeekend"] as? Int { self.wakeWeekend = self.dateFromMilitary(weekendInt) }

                self.sleepHoursWeekday = data["sleepHoursWeekday"] as? Double ?? 8
                self.sleepHoursWeekend = data["sleepHoursWeekend"] as? Double ?? 8
                self.workoutHoursPerDay = data["workoutHoursPerDay"] as? Double ?? 1
                self.screenLimitHours = data["screenLimitHours"] as? Double ?? 2
                self.weightLbs = data["weightLbs"] as? Int ?? 160
                self.updateWater()

                if let days = data["coldShowerDays"] as? [Int] {
                    self.coldShowerDays = Set(days)
                }

                self.addictionDaysPerWeek = data["addictionDaysPerWeek"] as? Int ?? 0

                if let days = data["workoutDays"] as? [Int] {
                    self.workoutDays = Set(days)
                }

                if let activities = data["selectedActivities"] as? [String: Any] {
                    var mapped: [String: [Int]] = [:]
                    for (key, value) in activities {
                        let normalizedKey = key.capitalized
                        if let arr = value as? [Int] {
                            mapped[normalizedKey] = arr
                        } else if let single = value as? Int {
                            mapped[normalizedKey] = [single]
                        }
                    }
                    self.selectedActivities = mapped
                }
            }
        }
    }

    private func dateFromMilitary(_ value: Int) -> Date {
        let hour = value / 100
        let minute = value % 100
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    private func savePreferences() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Session expired. Please log in again."
            showError = true
            return
        }
        isSaving = true

        let docRef = Firestore.firestore().collection("users").document(uid)
        let normalizedActivities = Dictionary(uniqueKeysWithValues:
            selectedActivities.map { key, value in (key.lowercased(), value) }
        )

        let payload: [String: Any] = [
            "majorFocus": majorFocus,
            "wakeWeekday": militaryTimeInt(from: wakeWeekday),
            "wakeWeekend": militaryTimeInt(from: wakeWeekend),
            "sleepHoursWeekday": sleepHoursWeekday,
            "sleepHoursWeekend": sleepHoursWeekend,
            "workoutHoursPerDay": workoutHoursPerDay,
            "screenLimitHours": screenLimitHours,
            "weightLbs": weightLbs,
            "waterOunces": waterOunces,
            "coldShowerDays": Array(coldShowerDays),
            "addictionDaysPerWeek": addictionDaysPerWeek,
            "workoutDays": Array(workoutDays).sorted(),
            "selectedActivities": normalizedActivities
        ]

        docRef.setData(payload, merge: true) { err in
            DispatchQueue.main.async {
                if err != nil {
                    self.isSaving = false
                    self.errorMessage = "Failed to save preferences. Please try again."
                    self.showError = true
                    return
                }

                self.isSaving = false
                // Wake/sleep times changed, so refresh the scheduled notifications.
                NotificationCenter.default.post(name: .ariseRescheduleNotifications, object: nil)
                if self.animationsEnabled {
                    withAnimation { self.savedSuccessfully = true }
                } else {
                    self.savedSuccessfully = true
                }
            }
        }
    }
}
