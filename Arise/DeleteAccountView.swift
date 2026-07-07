import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import AuthenticationServices
import GoogleSignIn

// MARK: - Apple Reauth Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static var current: AppleSignInCoordinator? = nil

    var completion: ((AuthCredential?) -> Void)?
    private var currentNonce: String?
    private weak var presentationWindow: UIWindow?

    init(presentationWindow: UIWindow?) {
        self.presentationWindow = presentationWindow
    }

    func startSignInWithAppleFlow() {
        // keep alive until flow completes
        AppleSignInCoordinator.current = self

        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // Required for presentation
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // prefer the supplied window, fall back to first window scene window
        if let w = presentationWindow { return w }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let win = windowScene.windows.first {
            return win
        }
        // last resort (shouldn't happen)
        return UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { AppleSignInCoordinator.current = nil }

        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let idTokenData = appleIDCredential.identityToken,
            let idTokenString = String(data: idTokenData, encoding: .utf8),
            let nonce = currentNonce
        else {
            completion?(nil)
            return
        }

        // Use the modern credential constructor
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        completion?(credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer { AppleSignInCoordinator.current = nil }
        completion?(nil)
    }
}

struct DeleteOptionButton: View {
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
                        .stroke(isSelected ? LinearGradient.brand : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing), lineWidth: isSelected ? 2 : 1)
                )
                .foregroundColor(.white)
        }
    }
}

struct DeleteAccountView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedReasons: Set<String> = []
    @State private var customReason: String = ""
    @State private var showConfirmation = false
    @State private var isDeleting = false
    @Binding var isUserLoggedIn: Bool
    
    let reasons = [
        "I don't find the app useful",
        "I have privacy concerns",
        "I want to start over",
        "I prefer another app",
        "Other"
    ]
    
    var body: some View {
        ScrollView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Why are you deleting your account?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(spacing: 16) {
                        ForEach(reasons, id: \.self) { reason in
                            DeleteOptionButton(
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
                    
                    Text("This action deletes all progress and data associated with this account and can not be reverted.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
                    .padding(.bottom, 60)
                }
                .padding()
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("This action is permanent and can not be undone. Are you sure?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .scrollIndicators(.hidden)
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }

        let providers = user.providerData.map { $0.providerID }

        if providers.contains("google.com") {
            reauthGoogleAndDelete(user: user)
        } else if providers.contains("apple.com") {
            reauthAppleAndDelete(user: user)
        } else {
            reauthEmailAndDelete(user: user)
        }
    }


    private func reauthAppleAndDelete(user: User) {
        // find a presentation window for the ASAuthorizationController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentationWindow = windowScene.windows.first else {
            return
        }

        let coordinator = AppleSignInCoordinator(presentationWindow: presentationWindow)
        coordinator.completion = { credential in
            guard let credential = credential else {
                return
            }

            user.reauthenticate(with: credential) { _, err in
                if err != nil {
                    return
                }

                Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { _, tokenErr in
                    if tokenErr != nil {
                        return
                    }

                    Auth.auth().currentUser?.reload(completion: { _ in
                        guard let refreshedUser = Auth.auth().currentUser else {
                            return
                        }

                        performDeleteWithChecks(uid: refreshedUser.uid, authUser: refreshedUser)
                    })
                }
            }
        }

        // Keep a strong ref while starting
        AppleSignInCoordinator.current = coordinator
        DispatchQueue.main.async {
            coordinator.startSignInWithAppleFlow()
        }
    }
    
    // --- New helper: heavily instrumented delete (copy/paste entire function) ---
    private func performDeleteWithChecks(uid: String, authUser: User) {
        isDeleting = true
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        docRef.getDocument { snapshot, getErr in
            if getErr != nil {
                self.isDeleting = false
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                docRef.delete { deleteErr in
                    if deleteErr != nil {
                        self.isDeleting = false
                        return
                    }

                    authUser.delete { authDeleteErr in
                        self.isDeleting = false
                        if authDeleteErr != nil {
                            return
                        }

                        do {
                            try Auth.auth().signOut()
                            isUserLoggedIn = false
                        } catch { }

                        dismiss()
                    }
                }
            } else {
                if let email = authUser.email {
                    db.collection("users").whereField("email", isEqualTo: email).getDocuments { qSnap, qErr in
                        if qErr != nil {
                            self.isDeleting = false
                            return
                        }

                        if let qSnap = qSnap, !qSnap.documents.isEmpty {
                            let batch = db.batch()
                            qSnap.documents.forEach { batch.deleteDocument($0.reference) }
                            batch.commit { batchErr in
                                if batchErr != nil {
                                    self.isDeleting = false
                                    return
                                }

                                authUser.delete { authDeleteErr in
                                    self.isDeleting = false
                                    if authDeleteErr != nil {
                                        return
                                    }

                                    do {
                                        try Auth.auth().signOut()
                                        isUserLoggedIn = false
                                    } catch { }
                                    dismiss()
                                }
                            }
                        } else {
                            authUser.delete { authDeleteErr in
                                self.isDeleting = false
                                if authDeleteErr != nil {
                                    return
                                }
                                do {
                                    try Auth.auth().signOut()
                                    isUserLoggedIn = false
                                } catch { }
                                dismiss()
                            }
                        }
                    }
                } else {
                    authUser.delete { authDeleteErr in
                        self.isDeleting = false
                        if authDeleteErr != nil {
                            return
                        }
                        do {
                            try Auth.auth().signOut()
                            isUserLoggedIn = false
                        } catch { }
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func reauthGoogleAndDelete(user: User) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if error != nil {
                return
            }

            guard let result = signInResult,
                  let idToken = result.user.idToken?.tokenString else {
                return
            }

            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            user.reauthenticate(with: credential) { _, error in
                if error != nil {
                    return
                }

                performDelete(user: user)
            }
        }
    }


    private func reauthEmailAndDelete(user: User) {
        let alert = UIAlertController(
            title: "Re-enter Password",
            message: "Please enter your password to confirm deletion.",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            guard let password = alert.textFields?.first?.text, !password.isEmpty,
                  let email = user.email else {
                return
            }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { _, error in
                if error != nil {
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
        let uid = user.uid

        db.collection("users").document(uid).delete { error in
            if error != nil {
                isDeleting = false
                return
            }

            user.delete { error in
                isDeleting = false
                if error != nil {
                    return
                }

                do {
                    try Auth.auth().signOut()
                    isUserLoggedIn = false
                } catch { }

                dismiss()
            }
        }
    }


}
