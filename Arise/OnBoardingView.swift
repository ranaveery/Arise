import SwiftUI
import FirebaseAuth
import Firebase

// PreferenceKey to measure bottom nav height
private struct NavHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var gender = ""
    @State private var ageRange = ""
    @State private var selectedAddictions: Set<String> = []
    @State private var workoutTypes: Set<String> = []
    @State private var dietaryPreference = ""
    @State private var healthProblems: Set<String> = []
    @State private var isSaving = false
    @State private var hasAgreedToTerms = false
    @State private var navHeight: CGFloat = 0   // <-- measured height for dot positioning

    let onFinish: () -> Void

    let workoutOptions = ["Strength training", "Cardio", "Yoga/Pilates", "HIIT", "Mixed"]
    let dietaryOptions = ["Vegan", "Vegetarian", "Keto", "Paleo", "None"]
    let healthProblemOptions = ["Back Pain", "Joint Pain", "High Blood Pressure", "Diabetes", "Asthma", "None"]
    let addictionOptions = ["Social Media", "Porn", "Vaping", "Smoking", "Alcohol", "Gaming", "None"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            // Main content (no dots here so they don't bounce)
            VStack(spacing: 40) {
                Spacer()
                stepView
                Spacer(minLength: 40)
            }

            // Dots are overlaid and pinned above the nav, regardless of step content height
            stepIndicator
                .padding(.bottom, navHeight + 12)
                .allowsHitTesting(false)

            // Bottom navigation (measured for positioning dots)
            bottomNavigation
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: NavHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
        }
        .onPreferenceChange(NavHeightPreferenceKey.self) { navHeight = $0 }
    }

    // MARK: - Step Content
    @ViewBuilder
    private var stepView: some View {
        switch currentStep {
        case 0:
            StepLogoView()
        case 1:
            StepGenderView(gender: $gender)
        case 2:
            StepSingleChoice(title: "Select your age group",
                             options: ["Under 18", "18–24", "25–34", "35+"],
                             selection: $ageRange)
        case 3:
            StepMultiChoice(title: "Habits to work on?",
                            options: addictionOptions,
                            selection: $selectedAddictions,
                            noneOption: "None")
        case 4:
            StepMultiChoice(title: "Preferred workout types?",
                            options: workoutOptions,
                            selection: $workoutTypes)
        case 5:
            StepSingleChoice(title: "Any dietary preferences?",
                             options: dietaryOptions,
                             selection: $dietaryPreference)
        case 6:
            StepMultiChoice(title: "Any health concerns?",
                            options: healthProblemOptions,
                            selection: $healthProblems,
                            noneOption: "None")
        case 7:
            StepTermsView(hasAgreedToTerms: $hasAgreedToTerms)
        default:
            EmptyView()
        }
    }

    // MARK: - Step Indicator (unchanged visuals)
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? AnyShapeStyle(gradientBackground) :
                          AnyShapeStyle(Color.white.opacity(0.2)))
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - Navigation Buttons
    private var bottomNavigation: some View {
        HStack {
            if currentStep > 0 {
                GradientButton(label: "Back", icon: "arrow.left") {
                    currentStep -= 1
                }
                .padding(.leading, 20)
            } else {
                Spacer().frame(width: 100)
            }

            Spacer()

            GradientButton(label: currentStep == 7 ? "Finish" : "Next",
                           icon: "arrow.right",
                           loading: isSaving) {
                handleContinue()
            }
            .padding(.trailing, 20)
            .disabled(
                (currentStep == 1 && gender.isEmpty) ||
                (currentStep == 2 && ageRange.isEmpty) ||
                (currentStep == 3 && selectedAddictions.isEmpty) ||
                (currentStep == 4 && workoutTypes.isEmpty) ||
                (currentStep == 5 && dietaryPreference.isEmpty) ||
                (currentStep == 7 && !hasAgreedToTerms)
            )
        }
        .padding(.bottom, 25)
    }

    // MARK: - Actions
    func handleContinue() {
        if currentStep < 7 {
            currentStep += 1
        } else {
            saveUserData()
        }
    }

    func saveUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { snapshot, error in
            guard error == nil else {
                isSaving = false
                return
            }
            
            var data: [String: Any] = [
                "gender": gender,
                "ageRange": ageRange,
                "addictions": Array(selectedAddictions),
                "workoutTypes": Array(workoutTypes),
                "dietaryPreference": dietaryPreference,
                "healthProblems": Array(healthProblems),
                "isOnboarded": true
            ]
            
            // If the user doc already exists, check if XP/skills are missing
            if let snap = snapshot, snap.exists {
                let existing = snap.data() ?? [:]
                if existing["xp"] == nil { data["xp"] = 0 }
                if existing["rank"] == nil { data["rank"] = "Novice" }
                if existing["level"] == nil { data["level"] = 1 }
                if existing["skills"] == nil {
                    data["skills"] = [
                        "Strength": ["level": 1, "xp": 0],
                        "Endurance": ["level": 1, "xp": 0],
                        "Focus": ["level": 1, "xp": 0],
                        "Creativity": ["level": 1, "xp": 0]
                    ]
                }
                if existing["notifications"] == nil {
                    data["notifications"] = [
                        "expiringTasks": true,
                        "newTasks": true,
                        "weeklyProgress": true
                    ]
                }
            } else {
                // Brand new doc
                data["xp"] = 0
                data["rank"] = "Novice"
                data["level"] = 1
                data["skills"] = [
                    "Strength": ["level": 1, "xp": 0],
                    "Endurance": ["level": 1, "xp": 0],
                    "Focus": ["level": 1, "xp": 0],
                    "Creativity": ["level": 1, "xp": 0]
                ]
                data["notifications"] = [
                    "expiringTasks": true,
                    "newTasks": true,
                    "weeklyProgress": true
                ]
            }
            
            userRef.setData(data, merge: true) { error in
                isSaving = false
                if error == nil { onFinish() }
            }
        }
    }

    // MARK: - Shared Gradient
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

// MARK: - Shared UI Components

struct GradientButton: View {
    let label: String
    let icon: String
    var loading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 140, height: 48)
                    .background(Color.black)
                    .cornerRadius(25)
            } else {
                HStack {
                    Text(label)
                    Image(systemName: icon)
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 84/255, green: 0/255, blue: 232/255),
                            Color(red: 236/255, green: 71/255, blue: 1/255)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(25)
            }
        }
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

// MARK: - Step Views

struct StepLogoView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var glowPulse = false
    @State private var logoTapped = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Image("logo_arise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .blur(radius: glowPulse ? 18 : 12)
                    .opacity(glowPulse ? 0.9 : 0.7)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                Image("logo_arise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(logoScale * (logoTapped ? 1.2 : 1.0))
                    .opacity(logoOpacity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: logoScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: logoTapped)
                    .onTapGesture {
                        logoTapped = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { logoTapped = false }
                    }
            }
            .padding(.bottom, 10)
            .onAppear {
                logoScale = 1.0
                logoOpacity = 1.0
                glowPulse = true
            }

            Text("Welcome to Arise")
                .font(.system(size: 34, weight: .bold))
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

            Text("Let’s tailor your experience.")
                .foregroundColor(.gray)
                .font(.title3.weight(.medium))

            VStack(spacing: 10) {
                Text("Your responses help us create a personalized experience.\nAll information is kept private and securely stored.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            Spacer(minLength: 80)
        }
    }
}

struct StepGenderView: View {
    @Binding var gender: String

    var body: some View {
        VStack(spacing: 24) {
            Text("Select your gender")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 24) {
                GenderOption(symbol: "figure.stand", label: "Male", isSelected: gender == "Male") { gender = "Male" }
                GenderOption(symbol: "figure.stand.dress", label: "Female", isSelected: gender == "Female") { gender = "Female" }
            }
            Text("This selection cannot be changed later.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct StepSingleChoice: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    OptionButton(text: option, isSelected: selection == option) {
                        selection = option
                    }
                }
            }
        }
    }
}

struct StepMultiChoice: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>
    var noneOption: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    OptionButton(text: option, isSelected: selection.contains(option)) {
                        if option == noneOption {
                            selection = selection.contains(option) ? [] : [option]
                        } else {
                            if selection.contains(option) {
                                selection.remove(option)
                            } else {
                                selection.insert(option)
                                if let none = noneOption { selection.remove(none) }
                            }
                        }
                    }
                }
            }
        }
    }
}


struct StepTermsView: View {
    @Binding var hasAgreedToTerms: Bool
    @State private var termsText: String = "Loading..."

    var body: some View {
        VStack(spacing: 20) {
            Text("Terms & Privacy Policy")
                .font(.title2.bold())
                .foregroundColor(.white)

            // Gray box for terms
            ScrollView {
                Text(termsText)
                    .foregroundColor(.white.opacity(0.85))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .background(Color.gray.opacity(0.25))
            .cornerRadius(16)

            // Custom checkbox
            Button(action: {
                hasAgreedToTerms.toggle()
            }) {
                HStack {
                    Image(systemName: hasAgreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(hasAgreedToTerms ? .purple : .white)
                        .font(.title2)

                    Text("I agree to the Terms & Privacy Policy")
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            loadTermsText()
        }
    }

    private func loadTermsText() {
        if let url = Bundle.main.url(forResource: "TermsAndPrivacy", withExtension: "txt"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            termsText = contents
        } else {
            termsText = "Unable to load Terms & Privacy Policy."
        }
    }
}
