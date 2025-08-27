import SwiftUI
import FirebaseAuth
import GoogleSignIn
import Firebase

struct LandingView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var showLogin: Bool
    
    @State private var currentPhraseIndex = 0
    @State private var displayedText = ""
    @State private var isActive = true       // track if LandingView is visible
    @State private var isDeleting = false
    @State private var typingTimer: Timer?
    @State private var charIndex = 0
    
    @State private var animateLogo = false   // NEW: for tap animation
    
    private let phrases = [
        "A new you begins here",
        "Awaken your potential",
        "It's time to Arise",
        "Rise beyond limits",
        "Unlock your true potential",
        "Build your best self",
        "Every step takes you higher",
        "Discipline creates freedom",
        "Arise. Improve. Become."
    ]



    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // App Logo
                        Image("logo_arise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(.bottom, 20)
                            .scaleEffect(animateLogo ? 1.1 : 1.0)          // animate size
                            .rotationEffect(.degrees(animateLogo ? 6 : 0)) // animate tilt
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: animateLogo)
                            .onTapGesture {
                                animateLogo = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    animateLogo = false
                                }
                            }
                            .padding(20)
                        
                        // Typing effect text
                        Text(displayedText)
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(minHeight: 40)
                    }
                    
                    Spacer()
                    
                    // Bottom sheet style box
                    VStack(spacing: 12) {
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image("google_logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                Text("Continue with Google")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                        
                        NavigationLink(destination: SignUpView(isUserLoggedIn: $isUserLoggedIn, showLogin: $showLogin)) {
                            Text("Sign up")
                                .font(.system(size: 18, weight: .semibold, design: .rounded)) // nicer rounded font
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(14)
                                .foregroundColor(.white)
                        }

                        NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn, showLogin: $showLogin)) {
                            Text("Log in")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .tracking(0.5)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 20/255, green: 20/255, blue: 20/255))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                                )
                                .cornerRadius(14)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(16)
                    .background(
                        Color(red: 30/255, green: 30/255, blue: 30/255)
                            .clipShape(TopRoundedRectangle(radius: 25))
                            .ignoresSafeArea(edges: .bottom) // << move here
                    )
                }
                .onAppear {
                    isActive = true
                    if typingTimer == nil {
                        startTypingEffect()
                    }
                }
                .onDisappear {
                    isActive = false
                    typingTimer?.invalidate()
                    typingTimer = nil
                }
            }
        }
    }
    
    // MARK: - Typing + Deleting effect with haptic feedback
        private func startTypingEffect() {
            typingTimer?.invalidate()
            guard isActive else { return }   // don’t start if LandingView is not active
    
            let phrase = phrases[currentPhraseIndex]
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.prepare()
    
            typingTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
                guard isActive else {   // stop immediately if user left
                    timer.invalidate()
                    typingTimer = nil
                    return
                }
    
                if !isDeleting {
                    if charIndex < phrase.count {
                        let i = phrase.index(phrase.startIndex, offsetBy: charIndex)
                        displayedText.append(phrase[i])
                        charIndex += 1
                        impact.impactOccurred()
                    } else {
                        timer.invalidate()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if isActive {   // only continue if still on LandingView
                                isDeleting = true
                                startTypingEffect()
                            }
                        }
                    }
                } else {
                    if !displayedText.isEmpty {
                        displayedText.removeLast()
                        charIndex -= 1
                        impact.impactOccurred()
                    } else {
                        timer.invalidate()
                        isDeleting = false
                        charIndex = 0
                        currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if isActive {   // only continue if still on LandingView
                                startTypingEffect()
                            }
                        }
                    }
                }
            }
        }
    
    // MARK: - Google Sign-In
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
                  let idTokenObj = user.idToken else {
                print("Missing user or ID token")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idTokenObj.tokenString,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase login failed:", error.localizedDescription)
                    return
                }
                
                guard let firebaseUser = result?.user else { return }
                
                let fullName = user.profile?.name ?? "No Name"
                let email = user.profile?.email ?? "No Email"
                let uid = firebaseUser.uid
                
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(uid)
                userRef.setData([
                    "name": fullName,
                    "email": email,
                    "uid": uid
                ], merge: true) { err in
                    if let err = err {
                        print("Error saving user to Firestore: \(err.localizedDescription)")
                    } else {
                        print("User saved to Firestore")
                    }
                }
                
                UserDefaults.standard.set(fullName, forKey: "userName")
                UserDefaults.standard.set(email, forKey: "userEmail")
                
                DispatchQueue.main.async {
                    isUserLoggedIn = true
                }
            }
        }
    }
}

struct TopRoundedRectangle: Shape {
    var radius: CGFloat = 25
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
