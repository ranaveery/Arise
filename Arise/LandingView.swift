import SwiftUI
import AuthenticationServices
import FirebaseAuth
import GoogleSignIn
import Firebase
import CryptoKit

// MARK: - Nonce Helper for Apple Sign-In
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with code \(errorCode)")
            }
            return random
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.map { String(format: "%02x", $0) }.joined()
}

struct LandingView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var showLogin: Bool
    @State private var currentNonce: String?
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
                        
                        SignInWithAppleButton(.signIn, onRequest: { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        }, onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    handleAppleSignIn(credential: appleIDCredential)
                                }
                            case .failure(let error):
                                print("Apple Sign-In failed: \(error.localizedDescription)")
                            }
                        })
                        .signInWithAppleButtonStyle(.whiteOutline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .padding(.horizontal, 1)
                        
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
    
    private func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            print("Missing nonce")
            return
        }
        
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            return
        }
        
        // Correct new API for FirebaseAuth 11+
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        Auth.auth().signIn(with: firebaseCredential) { result, error in
            if let error = error {
                print("Firebase Sign in with Apple error: \(error.localizedDescription)")
                return
            }
            
            guard let firebaseUser = result?.user else { return }
            let uid = firebaseUser.uid
            let fullName = credential.fullName?.givenName ?? "User"
            let email = credential.email ?? firebaseUser.email ?? "No Email"
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)
            userRef.setData([
                "name": fullName,
                "email": email,
                "uid": uid
            ], merge: true) { err in
                if let err = err {
                    print("Error saving Apple user to Firestore: \(err.localizedDescription)")
                } else {
                    print("Apple user saved to Firestore")
                }
            }
            
            UserDefaults.standard.set(fullName, forKey: "userName")
            UserDefaults.standard.set(email, forKey: "userEmail")
            
            DispatchQueue.main.async {
                isUserLoggedIn = true
            }
        }
    }
    
    // MARK: - Typing + Deleting effect with haptic feedback
    private func startTypingEffect() {
        typingTimer?.invalidate()
        guard isActive else { return }   // don’t start if LandingView is not active

        let phrase = phrases[currentPhraseIndex]
        
        // Separate generators for typing vs deleting
        let typingImpact = UIImpactFeedbackGenerator(style: .soft)
        let deletingImpact = UISelectionFeedbackGenerator()
        
        typingImpact.prepare()
        deletingImpact.prepare()

        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard isActive else {   // stop immediately if user left
                timer.invalidate()
                typingTimer = nil
                return
            }

            if !isDeleting {
                // Typing characters
                if charIndex < phrase.count {
                    let i = phrase.index(phrase.startIndex, offsetBy: charIndex)
                    displayedText.append(phrase[i])
                    charIndex += 1
                    typingImpact.impactOccurred()  // soft tap
                } else {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if isActive {
                            isDeleting = true
                            startTypingEffect()
                        }
                    }
                }
            } else {
                // Deleting characters
                if !displayedText.isEmpty {
                    displayedText.removeLast()
                    charIndex -= 1
                    deletingImpact.selectionChanged() // swoosh-like feedback
                } else {
                    timer.invalidate()
                    isDeleting = false
                    charIndex = 0
                    currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if isActive {
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
