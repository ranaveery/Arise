import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedReasons: Set<String> = []
    @State private var customReason: String = ""
    @State private var showConfirmation = false
    @State private var isDeleting = false
    
    let reasons = [
        "I don't find the app useful",
        "I have privacy concerns",
        "I want to start over",
        "I prefer another app",
        "Other"
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Why are you deleting your account?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(spacing: 16) {
                    ForEach(reasons, id: \.self) { reason in
                        OptionButton(
                            text: reason,
                            isSelected: selectedReasons.contains(reason)
                        ) {
                            if selectedReasons.contains(reason) {
                                selectedReasons.remove(reason)
                                if reason == "Other" { customReason = "" }
                            } else {
                                selectedReasons.insert(reason)
                            }
                        }
                    }
                    
                    if selectedReasons.contains("Other") {
                        TextField("Please tell us why...", text: $customReason)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple.opacity(0.7), lineWidth: 1)
                            )
                    }
                }
                
                Button(action: {
                    showConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Account")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .disabled(selectedReasons.isEmpty || (selectedReasons.contains("Other") && customReason.isEmpty))
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Delete Account")
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("This action is permanent. Are you sure?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }

        // Check if the user signed in with Google
        if user.providerData.contains(where: { $0.providerID == "google.com" }) {
            reauthGoogleAndDelete(user: user)
        } else {
            // Email/password
            reauthEmailAndDelete(user: user)
        }
    }

    private func reauthGoogleAndDelete(user: User) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("No root VC found")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard let result = signInResult,
                  let idToken = result.user.idToken?.tokenString else {
                print("Missing idToken")
                return
            }

            // Access token is NOT optional anymore
            let accessToken = result.user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    print("Reauthentication failed: \(error.localizedDescription)")
                    return
                }

                performDelete(user: user)
            }
        }
    }


    private func reauthEmailAndDelete(user: User) {
        // Prompt for password
        let alert = UIAlertController(title: "Re-enter Password",
                                      message: "Please enter your password to confirm deletion.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            guard let password = alert.textFields?.first?.text,
                  let email = user.email else { return }

            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    print("Reauthentication failed: \(error.localizedDescription)")
                    return
                }
                performDelete(user: user)
            }
        })

        // Present alert
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        rootVC.present(alert, animated: true)
    }

    private func performDelete(user: User) {
        isDeleting = true
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { _ in
            user.delete { error in
                isDeleting = false
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                } else {
                    print("Account deleted successfully")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
