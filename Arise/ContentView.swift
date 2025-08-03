import SwiftUI
import FirebaseAuth
import Firebase

struct ContentView: View {
    @State private var isOnboarded = false
    @State private var isCheckingStatus = true
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil
    @State private var showLogin = true

    var body: some View {
        Group {
            if isCheckingStatus {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView("Loading...")
                        .foregroundColor(.white)
                }
            } else if !isUserLoggedIn {
                LoginView(isUserLoggedIn: $isUserLoggedIn, showLogin: $showLogin)
            } else if isOnboarded {
                MainTabView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                OnboardingView {
                    self.isOnboarded = true
                }
            }
        }
        .onAppear {
            checkIfUserIsOnboarded()
        }
    }

    func checkIfUserIsOnboarded() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.isUserLoggedIn = false
            self.isCheckingStatus = false
            return
        }

        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let onboarded = data["isOnboarded"] as? Bool {
                self.isOnboarded = onboarded
            } else {
                self.isOnboarded = false
            }
            self.isCheckingStatus = false
        }
    }
}
