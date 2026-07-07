import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthGateView: View {
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil
    @State private var showLogin = true
    @State private var isOnboarded = false
    @State private var checkingOnboarding = false
    @State private var authListener: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if isUserLoggedIn {
                if checkingOnboarding {
                    VStack {
                        Spacer()
                        Image("logo_arise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
 else if !isOnboarded {
                    OnboardingView {
                        self.isOnboarded = true
                    }
                } else {
                    MainTabView(isUserLoggedIn: $isUserLoggedIn)
                }
            } else {
                ZStack {
                    if showLogin {
                        LandingView(isUserLoggedIn: $isUserLoggedIn, showLogin: $showLogin)
                            .transition(.move(edge: .leading))
                    } else {
                        SignUpView(isUserLoggedIn: $isUserLoggedIn, showLogin: $showLogin)
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut, value: showLogin)
            }
        }
        .onAppear {
            if let listener = authListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                isUserLoggedIn = (user != nil)
                if isUserLoggedIn {
                    checkIfUserIsOnboarded()
                } else {
                    isOnboarded = false
                }
            }
        }
        .onDisappear {
            if let listener = authListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }

    private func checkIfUserIsOnboarded() {
        checkingOnboarding = true
        guard let uid = Auth.auth().currentUser?.uid else {
            isOnboarded = false
            checkingOnboarding = false
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.isOnboarded = false
                } else if let data = snapshot?.data(), let onboarded = data["isOnboarded"] as? Bool {
                    self.isOnboarded = onboarded
                } else {
                    self.isOnboarded = false
                }
                self.checkingOnboarding = false
            }
        }
    }
}
