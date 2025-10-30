import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore
import AuthenticationServices
import CryptoKit

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
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
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
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}

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
            print("AppleSignInCoordinator: missing token/nonce")
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
        print("AppleSignInCoordinator: Sign in failed: \(error.localizedDescription)")
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

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentationMode
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
            print("reauthAppleAndDelete: no window Scene/window available")
            return
        }

        let coordinator = AppleSignInCoordinator(presentationWindow: presentationWindow)
        coordinator.completion = { credential in
            guard let credential = credential else {
                print("reauthAppleAndDelete: credential missing")
                return
            }

            // Reauthenticate the user with the obtained credential
            user.reauthenticate(with: credential) { _, err in
                if let err = err {
                    print("reauthAppleAndDelete: reauthenticate error: \(err.localizedDescription) -- \(String(describing: (err as NSError?).map { $0.code }))")
                    return
                }

                // Force refresh the ID token to ensure Firestore sees fresh credentials
                Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, tokenErr in
                    if let tokenErr = tokenErr {
                        print("reauthAppleAndDelete: getIDTokenForcingRefresh error: \(tokenErr.localizedDescription)")
                        return
                    }

                    // reload user to ensure local state is updated
                    Auth.auth().currentUser?.reload(completion: { reloadErr in
                        if let reloadErr = reloadErr {
                            print("reauthAppleAndDelete: reload error: \(reloadErr.localizedDescription)")
                            // continue anyway - but log it
                        }

                        // At this point we should have a fresh currentUser. Use it.
                        guard let refreshedUser = Auth.auth().currentUser else {
                            print("reauthAppleAndDelete: Auth.auth().currentUser is nil after reauth")
                            return
                        }

                        // call the debug+delete helper
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

        print("[delete] Attempting deletion for uid: \(uid)")
        print("[delete] Current Auth uid: \(Auth.auth().currentUser?.uid ?? "nil")")
        print("[delete] ProviderData: \(Auth.auth().currentUser?.providerData.map { $0.providerID } ?? [])")

        // Step A: check doc existence at users/{uid}
        docRef.getDocument { snapshot, getErr in
            if let getErr = getErr {
                print("[delete] getDocument failed: \(getErr.localizedDescription) code: \((getErr as NSError).code)")
                self.isDeleting = false
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                print("[delete] Found users/\(uid) document. data: \(snapshot.data() ?? [:])")

                // Try to delete doc directly
                docRef.delete { deleteErr in
                    if let deleteErr = deleteErr {
                        let ns = deleteErr as NSError
                        print("[delete] delete(doc) failed: \(deleteErr.localizedDescription) code: \(ns.code), domain: \(ns.domain)")
                        self.isDeleting = false

                        // If permission denied, give actionable next steps
                        if ns.code == 7 /* GRPC_PERMISSION_DENIED */ || ns.code == 403 {
                            print("[delete] Permission denied deleting Firestore doc. Likely Firestore security rules blocking client deletes. Use server-side cleanup (cloud function) or adjust rules.")
                        }
                        return
                    }

                    print("[delete] Firestore document deleted successfully for users/\(uid). Proceeding to delete Auth user.")

                    // Now delete Auth user
                    authUser.delete { authDeleteErr in
                        self.isDeleting = false
                        if let authDeleteErr = authDeleteErr {
                            print("[delete] authUser.delete failed: \(authDeleteErr.localizedDescription) code: \((authDeleteErr as NSError).code)")
                            return
                        }

                        print("[delete] Auth user deleted successfully.")
                        do {
                            try Auth.auth().signOut()
                            isUserLoggedIn = false
                        } catch {
                            print("[delete] signOut error: \(error.localizedDescription)")
                        }

                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                // Document not found at users/{uid}. Try searching by email
                print("[delete] No document found at users/\(uid). Searching by email...")

                if let email = authUser.email {
                    db.collection("users").whereField("email", isEqualTo: email).getDocuments { qSnap, qErr in
                        if let qErr = qErr {
                            print("[delete] query by email failed: \(qErr.localizedDescription) code: \((qErr as NSError).code)")
                            self.isDeleting = false
                            return
                        }

                        if let qSnap = qSnap, !qSnap.documents.isEmpty {
                            print("[delete] Found \(qSnap.documents.count) document(s) matching email \(email). Will delete them all (IDs: \(qSnap.documents.map { $0.documentID }))")

                            let batch = db.batch()
                            qSnap.documents.forEach { batch.deleteDocument($0.reference) }
                            batch.commit { batchErr in
                                if let batchErr = batchErr {
                                    print("[delete] batch delete failed: \(batchErr.localizedDescription) code: \((batchErr as NSError).code)")
                                    self.isDeleting = false
                                    return
                                }

                                print("[delete] Documents matched by email deleted. Now deleting Auth user.")
                                authUser.delete { authDeleteErr in
                                    self.isDeleting = false
                                    if let authDeleteErr = authDeleteErr {
                                        print("[delete] authUser.delete failed: \(authDeleteErr.localizedDescription) code: \((authDeleteErr as NSError).code)")
                                        return
                                    }

                                    print("[delete] Auth user deleted successfully.")
                                    do {
                                        try Auth.auth().signOut()
                                        isUserLoggedIn = false
                                    } catch {
                                        print("[delete] signOut error: \(error.localizedDescription)")
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        } else {
                            print("[delete] No matching documents by uid or email. This means the Firestore user doc likely uses a different ID or is stored elsewhere.")
                            // Still attempt deleting the Auth user (optional)
                            print("[delete] Proceeding to delete Auth user anyway.")
                            authUser.delete { authDeleteErr in
                                self.isDeleting = false
                                if let authDeleteErr = authDeleteErr {
                                    print("[delete] authUser.delete failed: \(authDeleteErr.localizedDescription) code: \((authDeleteErr as NSError).code)")
                                    return
                                }
                                print("[delete] Auth user deleted successfully (no Firestore doc found).")
                                do {
                                    try Auth.auth().signOut()
                                    isUserLoggedIn = false
                                } catch {
                                    print("[delete] signOut error: \(error.localizedDescription)")
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                } else {
                    print("[delete] No email on user to search by. Proceeding to delete Auth user (best-effort).")
                    authUser.delete { authDeleteErr in
                        self.isDeleting = false
                        if let authDeleteErr = authDeleteErr {
                            print("[delete] authUser.delete failed: \(authDeleteErr.localizedDescription) code: \((authDeleteErr as NSError).code)")
                            return
                        }
                        print("[delete] Auth user deleted successfully (no Firestore doc found, no email).")
                        do {
                            try Auth.auth().signOut()
                            isUserLoggedIn = false
                        } catch {
                            print("[delete] signOut error: \(error.localizedDescription)")
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func reauthGoogleAndDelete(user: User) {
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
                print("Password missing")
                return
            }
            
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
        let uid = user.uid  // Save before deleting user

        // Step 1: Delete Firestore data first
        db.collection("users").document(uid).delete { error in
            if let error = error {
                isDeleting = false
                print("Error deleting Firestore data: \(error.localizedDescription)")
                return
            }

            print("Firestore document deleted successfully")

            // Step 2: Now delete Firebase Auth user
            user.delete { error in
                isDeleting = false
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                    return
                }

                print("Account deleted successfully")

                // Step 3: Sign out and close view
                do {
                    try Auth.auth().signOut()
                    isUserLoggedIn = false
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }

                presentationMode.wrappedValue.dismiss()
            }
        }
    }


}
