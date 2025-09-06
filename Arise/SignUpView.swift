import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn

struct SignUpView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var showLogin: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image("logo_arise")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .padding(.top, 10)

            Text("Get Started")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            VStack(spacing: 16) {
                TextField("Name", text: $name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .onChange(of: name) { oldValue, newValue in
                        name = Self.sanitizeName(newValue)
                    }

                TextField("Email", text: $email)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, -4)
                }
            }

            Button(action: registerUser) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(25)
                } else {
                    Text("Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 84/255, green: 0/255, blue: 232/255),
                                Color(red: 236/255, green: 71/255, blue: 1/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }

            HStack(spacing: 4) {
                Text("Have an account?")
                    .foregroundColor(.white)
                Button(action: {
                    withAnimation {
                        dismiss()  // Takes user back to LandingView
                    }
                }) {
                    Text("Log in")
                        .foregroundColor(Color.blue)
                        .fontWeight(.semibold)
                }
            }

            HStack {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                Text("OR")
                    .foregroundColor(.gray)
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            }
            .padding(.vertical, 10)

            Button(action: signInWithGoogle) {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)

                    Text("Continue with Google")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
                .cornerRadius(30)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
    
    private static func sanitizeName(_ input: String) -> String {
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: "-"))
        let filtered = input.unicodeScalars
            .filter { allowed.contains($0) }
            .map { String($0) }
            .joined()

        var result = ""
        var capitalizeNext = true
        for char in filtered {
            if char == "-" {
                result.append(char)
                capitalizeNext = true
            } else {
                if capitalizeNext {
                    result.append(char.uppercased())
                    capitalizeNext = false
                } else {
                    result.append(char.lowercased())
                }
            }
        }
        return result
    }

    private func registerUser() {
        isLoading = true
        errorMessage = ""

        // Validation
        guard !name.isEmpty else {
            errorMessage = "Name is required."
            isLoading = false
            return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Invalid email format."
            isLoading = false
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            isLoading = false
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(user.uid)

                userRef.setData([
                    "name": Self.sanitizeName(name),
                    "email": email,
                    "rank": "Seeker",
                    "xp": 0,
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
                ]) { error in
                    if let error = error {
                        print("Failed to save user data: \(error.localizedDescription)")
                    } else {
                        print("User data saved successfully.")
                    }
                }
                DispatchQueue.main.async {
                    isUserLoggedIn = true
                }
            }
        }
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No rootViewController found")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: nil,
            nonce: nil
        ) { signInResult, error in
            if let error = error {
                print("Google Sign-In failed:", error.localizedDescription)
                return
            }

            guard let user = signInResult?.user,
                  let idToken = user.idToken else {
                print("Missing user or ID token")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase login failed:", error.localizedDescription)
                    return
                }

                guard let firebaseUser = result?.user else { return }
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(firebaseUser.uid)

                userRef.getDocument { snapshot, error in
                    if let snapshot = snapshot, snapshot.exists {
                        print("User already exists in Firestore")
                        DispatchQueue.main.async {
                            isUserLoggedIn = true
                        }
                    } else {
                        let name = user.profile?.name ?? "Unnamed"
                        let email = user.profile?.email ?? firebaseUser.email ?? ""

                        userRef.setData([
                            "name": name,
                            "email": email,
                            "rank": "Seeker",
                            "xp": 0,
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
                        ]) { error in
                            if let error = error {
                                print("Error saving Google user data:", error.localizedDescription)
                            } else {
                                print("Google user data saved")
                            }
                            DispatchQueue.main.async {
                                isUserLoggedIn = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    
}
