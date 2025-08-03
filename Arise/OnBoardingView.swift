
import SwiftUI
import FirebaseAuth
import Firebase

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var gender = ""
    @State private var ageRange = ""
    @State private var selectedAddictions: Set<String> = []
    @State private var workoutTypes: Set<String> = []
    @State private var dietaryPreference = ""
    @State private var healthProblems: Set<String> = []
    @State private var isSaving = false

    let onFinish: () -> Void

    // Constants for options
    let workoutOptions = ["Strength training", "Cardio", "Yoga/Pilates", "HIIT", "Mixed"]
    let dietaryOptions = ["Vegan", "Vegetarian", "Keto", "Paleo", "None"]
    let healthProblemOptions = ["Back Pain", "Joint Pain", "High Blood Pressure", "Diabetes", "Asthma", "None"]
    let addictionOptions = ["Social Media", "Porn", "Vaping", "Smoking", "Alcohol", "Gaming", "None"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Group {
                    if currentStep == 0 {
                        VStack(spacing: 10) {
                            Text("Welcome to Arise")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Text("Let’s get to know you.")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    }

                    if currentStep == 1 {
                        VStack(spacing: 24) {
                            Text("What’s your gender?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 24) {
                                GenderOption(
                                    symbol: "figure.stand",
                                    label: "Male",
                                    isSelected: gender == "Male"
                                ) { gender = "Male" }

                                GenderOption(
                                    symbol: "figure.stand.dress",
                                    label: "Female",
                                    isSelected: gender == "Female"
                                ) { gender = "Female" }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }

                    if currentStep == 2 {
                        VStack(spacing: 24) {
                            Text("What’s your age?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            VStack(spacing: 16) {
                                ForEach(["Under 18", "18–24", "25–34", "35+"], id: \.self) { option in
                                    OptionButton(
                                        text: option,
                                        isSelected: ageRange == option
                                    ) {
                                        ageRange = option
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }

                    if currentStep == 3 {
                        VStack(spacing: 24) {
                            Text("Addictions to work on?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            VStack(spacing: 16) {
                                ForEach(addictionOptions, id: \.self) { option in
                                    OptionButton(
                                        text: option,
                                        isSelected: selectedAddictions.contains(option)
                                    ) {
                                        if selectedAddictions.contains(option) {
                                            selectedAddictions.remove(option)
                                        } else {
                                            selectedAddictions.insert(option)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    
                    if currentStep == 4 {
                        VStack(spacing: 24) {
                            Text("Preferred workout types?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(workoutOptions, id: \.self) { option in
                                        MultiSelectOptionButton(
                                            text: option,
                                            isSelected: workoutTypes.contains(option)
                                        ) {
                                            if workoutTypes.contains(option) {
                                                workoutTypes.remove(option)
                                            } else {
                                                workoutTypes.insert(option)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    
                    if currentStep == 5 {
                        VStack(spacing: 24) {
                            Text("Dietary preference?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                ForEach(dietaryOptions, id: \.self) { option in
                                    OptionButton(
                                        text: option,
                                        isSelected: dietaryPreference == option
                                    ) {
                                        dietaryPreference = option
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    
                    if currentStep == 6 {
                        VStack(spacing: 24) {
                            Text("Any common health issues?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(healthProblemOptions, id: \.self) { option in
                                        // If "None" is selected, deselect others and vice versa
                                        let isSelected = healthProblems.contains(option)
                                        MultiSelectOptionButton(
                                            text: option,
                                            isSelected: isSelected
                                        ) {
                                            if option == "None" {
                                                if isSelected {
                                                    healthProblems.remove(option)
                                                } else {
                                                    healthProblems = [option]
                                                }
                                            } else {
                                                if isSelected {
                                                    healthProblems.remove(option)
                                                } else {
                                                    healthProblems.remove("None")
                                                    healthProblems.insert(option)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                
                // Step indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? AnyShapeStyle(gradientBackground) : AnyShapeStyle(Color.white.opacity(0.2)))
                            .frame(width: 10, height: 10)
                    }
                }

                Spacer(minLength: 40)
            }

            // Bottom navigation
            HStack {
                // Back Button
                if currentStep > 0 {
                    Button(action: {
                        currentStep -= 1
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(gradientBackground)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    .padding(.leading, 20)
                } else {
                    Spacer().frame(width: 100)
                }

                Spacer()

                // Continue Button
                Button(action: handleContinue) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 140, height: 48)
                            .background(Color.black)
                            .cornerRadius(25)
                    } else {
                        HStack(spacing: 6) {
                            Text(currentStep == 6 ? "Finish" : "Next")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(gradientBackground)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                }
                .padding(.trailing, 20)
                .disabled(
                    (currentStep == 1 && gender.isEmpty) ||
                    (currentStep == 2 && ageRange.isEmpty) ||
                    (currentStep == 3 && selectedAddictions.isEmpty) ||
                    (currentStep == 4 && workoutTypes.isEmpty) ||
                    (currentStep == 5 && dietaryPreference.isEmpty)
                )
            }
            .padding(.bottom, 25)
        }
    }

    func handleContinue() {
        if currentStep < 6 {
            currentStep += 1
        } else {
            saveUserData()
        }
    }

    func saveUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "gender": gender,
            "ageRange": ageRange,
            "addictions": Array(selectedAddictions),
            "workoutTypes": Array(workoutTypes),
            "dietaryPreference": dietaryPreference,
            "healthProblems": Array(healthProblems),
            "isOnboarded": true
        ], merge: true) { error in
            isSaving = false
            if error == nil {
                onFinish()
            }
        }
    }

    var gradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 84/255, green: 0/255, blue: 232/255),
                Color(red: 236/255, green: 71/255, blue: 1/255)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct GenderOption: View {
    let symbol: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 84/255, green: 0/255, blue: 232/255),
                        Color(red: 236/255, green: 71/255, blue: 1/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(
                    Image(systemName: symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                )

                Text(label)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(width: 100, height: 120)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(gradientStroke(isSelected), lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    func gradientStroke(_ active: Bool) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: active
                ? [Color(red: 84/255, green: 0/255, blue: 232/255),
                   Color(red: 236/255, green: 71/255, blue: 1/255)]
                : [.clear, .clear]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
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
