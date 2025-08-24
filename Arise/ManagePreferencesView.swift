import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ManagePreferencesView: View {
    @State private var gender = ""
    @State private var ageRange = ""
    @State private var selectedAddictions: Set<String> = []
    @State private var workoutTypes: Set<String> = []
    @State private var dietaryPreference = ""
    @State private var healthProblems: Set<String> = []
    @State private var isSaving = false
    @State private var savedSuccessfully = false
    
    // Dropdown states
    @State private var showAgePicker = false
    @State private var showAddictionsPicker = false
    @State private var showWorkoutPicker = false
    @State private var showDietaryPicker = false
    @State private var showHealthPicker = false
    
    // Constants
    private let workoutOptions = ["Strength training", "Cardio", "Yoga/Pilates", "HIIT", "Mixed"]
    private let dietaryOptions = ["Vegan", "Vegetarian", "Keto", "Paleo", "None"]
    private let healthProblemOptions = ["Back Pain", "Joint Pain", "High Blood Pressure", "Diabetes", "Asthma", "None"]
    private let addictionOptions = ["Social Media", "Porn", "Vaping", "Smoking", "Alcohol", "Gaming", "None"]
    
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
                    preferenceRow(title: "Gender", value: gender.isEmpty ? "Not set" : gender, systemImage: "person.fill", isEditable: false)
                    
                    preferenceRow(title: "Age Range", value: ageRange.isEmpty ? "Not set" : ageRange, systemImage: "calendar", isEditable: true, isExpanded: $showAgePicker) {
                        VStack(spacing: 5) {
                            ForEach(["Under 18", "18–24", "25–34", "35+"], id: \.self) { option in
                                dropdownOption(option, isSelected: ageRange == option) { changePreference { ageRange = option } }
                                .transition(.opacity)                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    preferenceRow(title: "Habits to Work On", value: selectedAddictions.isEmpty ? "None" : selectedAddictions.joined(separator: ", "), systemImage: "flame.fill", isEditable: true, isExpanded: $showAddictionsPicker) {
                        VStack(spacing: 5) {
                            ForEach(addictionOptions, id: \.self) { option in
                                MultiSelectOptionButton(text: option, isSelected: selectedAddictions.contains(option)) { changePreference { toggleSelection(option: option, in: &selectedAddictions) } }
                                .transition(.opacity)                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    preferenceRow(title: "Workout Types", value: workoutTypes.isEmpty ? "None" : workoutTypes.joined(separator: ", "), systemImage: "figure.walk", isEditable: true, isExpanded: $showWorkoutPicker) {
                        VStack(spacing: 5) {
                            ForEach(workoutOptions, id: \.self) { option in
                                MultiSelectOptionButton(text: option, isSelected: workoutTypes.contains(option)) { changePreference { toggleSelection(option: option, in: &workoutTypes) } }
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    preferenceRow(title: "Dietary Preference", value: dietaryPreference.isEmpty ? "None" : dietaryPreference, systemImage: "leaf.fill", isEditable: true, isExpanded: $showDietaryPicker) {
                        VStack(spacing: 5) {
                            ForEach(dietaryOptions, id: \.self) { option in
                                dropdownOption(option, isSelected: dietaryPreference == option) { changePreference { dietaryPreference = option } }
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    preferenceRow(title: "Health Concerns", value: healthProblems.isEmpty ? "None" : healthProblems.joined(separator: ", "), systemImage: "cross.case.fill", isEditable: true, isExpanded: $showHealthPicker) {
                        VStack(spacing: 5) {
                            ForEach(healthProblemOptions, id: \.self) { option in
                                MultiSelectOptionButton(text: option, isSelected: healthProblems.contains(option)) { changePreference { toggleSelection(option: option, in: &healthProblems) } }
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button(action: savePreferences) {
                    ZStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        } else {
                            HStack {
                                if savedSuccessfully {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .transition(.scale)
                                }
                                Text(savedSuccessfully ? "Saved" : "Save Changes")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(gradient)
                            .cornerRadius(12)
                            .animation(.spring(), value: savedSuccessfully)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .disabled(isSaving)
                
                Text("Once set, gender cannot be changed.")
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
    
    // MARK: - UI Helpers
    
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
    
    private func toggleSelection(option: String, in set: inout Set<String>) {
        if option == "None" {
            if set.contains("None") {
                set.remove("None")
            } else {
                set = ["None"]
            }
        } else {
            if set.contains(option) {
                set.remove(option)
            } else {
                set.insert(option)
                set.remove("None")
            }
        }
    }
    
    private func changePreference(_ action: @escaping () -> Void) {
        action()
        savedSuccessfully = false
    }
    
    private func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            gender = data["gender"] as? String ?? ""
            ageRange = data["ageRange"] as? String ?? ""
            dietaryPreference = data["dietaryPreference"] as? String ?? ""
            
            if let addictions = data["addictions"] as? [String] {
                selectedAddictions = Set(addictions)
            }
            if let workouts = data["workoutTypes"] as? [String] {
                workoutTypes = Set(workouts)
            }
            if let healths = data["healthProblems"] as? [String] {
                healthProblems = Set(healths)
            }
        }
    }
    
    private func savePreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "ageRange": ageRange,
            "addictions": Array(selectedAddictions),
            "workoutTypes": Array(workoutTypes),
            "dietaryPreference": dietaryPreference,
            "healthProblems": Array(healthProblems)
        ], merge: true) { _ in
            isSaving = false
            withAnimation { savedSuccessfully = true }
        }
    }
}
